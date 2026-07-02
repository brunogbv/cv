---
description: "Task list for Migrate hosting & CD to Vercel"
---

# Tasks: Migrate hosting & CD to Vercel

**Input**: Design documents from `/specs/001-vercel-cd-migration/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: None. This repo has no test suite (constitution Principle IV); verification is `make lint`
(Super-Linter, the CI gate) + the `quickstart.md` scenarios. No test tasks are generated.

**Organization**: Grouped by user story (US1/P1 → US2/P2 → US3/P3). Unlike a typical multi-story
feature, **these stories are sequential**: US2 (cutover) needs US1 (working deploy) live, and US3
(retire the VM stack) is only safe after US2 is verified.

**Owner-run tasks**: some steps happen in the Vercel dashboard / DNS registrar and **cannot be done
from the repo** — they are marked **(owner-run)** with the location instead of a file path.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3 (setup, foundational, and polish tasks have no story label)

---

## Phase 1: Setup (credentials & Vercel project config)

**Purpose**: one-time prerequisites so CLI deploys work and Vercel stops its own failing builds.

- [ ] T001 **(owner-run — Vercel dashboard)** In the `cv` Vercel project, disconnect the GitHub Git
      integration (Settings → Git) so no server-side auto-builds run; CLI `--prebuilt` deploys are
      unaffected.
- [ ] T002 **(owner-run — Vercel dashboard/CLI + GitHub)** Create a Vercel token; run `vercel link`
      to obtain `VERCEL_ORG_ID` + `VERCEL_PROJECT_ID` (from `.vercel/project.json`); add
      `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` as GitHub Actions repository secrets.

---

## Phase 2: Foundational — reproducible, self-contained build (issue #24)

**Purpose**: make the build deterministic and offline-safe. **⚠️ Blocks US1** — no deploy is
reliable until the build no longer depends on remote CDNs and the PDF step is awaited/fatal.

- [ ] T003 [P] Vendor Bootstrap 5.2.0 CSS into `src/assets/vendor/bootstrap/` (the `bootstrap.min.css`
      currently loaded from jsDelivr)
- [ ] T004 [P] Vendor Font Awesome 6.1.2 (CSS + `webfonts/`) into `src/assets/vendor/fontawesome/`
      (currently loaded from cdnjs)
- [ ] T005 [P] Vendor Roboto 400/500 (`woff2` + an `@font-face` CSS) into `src/assets/vendor/roboto/`
      (currently loaded from Google Fonts)
- [ ] T006 Update `src/templates/index.html`: replace the CDN `<link>`s (Google Fonts preconnect +
      Roboto, Bootstrap, Font Awesome) with references to the vendored files under `assets/vendor/`
- [ ] T007 Update `src/utils/pdf.js`: use `waitUntil: 'load'`, `await page.evaluate(() =>
      document.fonts.ready)` before `page.pdf()`, and set an explicit `page.goto` timeout
- [ ] T008 Update `src/build.js`: wrap the build body in an async IIFE, `await buildPdf(...)`, and
      `.catch(err => { console.error(err); process.exit(1) })` so a PDF failure fails the build
      (currently `buildPdf` is called unawaited)
- [ ] T009 Verify offline reproducibility: run `make page` with CDN/network access blocked → HTML +
      correctly-fonted PDF produced; `grep "https://" dist/index.html` shows no font/CSS CDN links
      (quickstart Scenario 1 / SC-003)

**Checkpoint**: the build is deterministic and offline-safe — US1 can begin.

---

## Phase 3: User Story 1 — platform builds & serves (Priority: P1) 🎯 MVP

**Goal**: every push produces a working deployment (production from `main`, preview per PR) serving
HTML + PDF, with automatic TLS — no manual server/cert steps.

**Independent Test**: open a PR → a preview URL serves the page + PDF over HTTPS; merge to `main` →
production deploy aliased to the project domain (quickstart Scenarios 2–3).

- [X] T010 [US1] Add `vercel.json` at repo root: `framework: null`, `buildCommand: ""`,
      `outputDirectory: "dist"`, `cleanUrls: true`, `trailingSlash: false`,
      `git.deploymentEnabled: false`, and the `headers` (Cache-Control per type + security headers)
      from `contracts/serving-contract.md`; add `.vercel/` to `.gitignore`
- [X] T011 [US1] Add a `deploy` target to `Makefile` wrapping `vercel pull` → `vercel build` →
      `vercel deploy --prebuilt` (reading `VERCEL_*` from the env; `--prod` when `PROD=1`); add
      `deploy` to `.PHONY`
- [X] T012 [US1] Add `.github/workflows/deploy.yml`: trigger on `push` to `main` (production) and
      `pull_request` (preview); steps = Node 22 + `npm ci`, cache `~/.cache/ms-playwright` (keyed on
      the Playwright version + runner OS), `npx playwright install --with-deps chromium`,
      `make page`, then `make deploy` (`PROD=1` on `main`)
- [X] T013 [US1] In `deploy.yml`, capture the deploy URL from stdout and post it to the PR
      (`actions/github-script` or `gh pr comment`) so preview URLs are visible (FR-002)
- [X] T014 [US1] Verify: PR → workflow builds + posts a working preview URL (HTML + PDF, correct
      fonts, `/<slug>.pdf` reachable); a forced build failure promotes nothing (FR-008); prod path
      aliases correctly (quickstart Scenarios 2–3 / SC-001, SC-002)

**Checkpoint**: the site builds and serves from Vercel on every push. MVP complete — deployable.

---

## Phase 4: User Story 2 — domain cutover (Priority: P2)

**Goal**: `valerio.dev` (canonical) + `www` serve from Vercel over auto-managed TLS; `www` 301s to
apex. Restores the currently-down site. **Depends on US1** (a working prod deploy must exist).

**Independent Test**: `dig`/`curl` show apex served over valid TLS and `www` → 301 → apex
(quickstart Scenario 4).

- [X] T015 [US2] Write the DNS cutover runbook in `docs/` (e.g. a "Domain cutover" section of
      `docs/ci-cd.md`): lower TTL → add domains in Vercel → set `www` → 301 → apex → verify serving +
      cert **before** switching → set A/CNAME → verify. Note there is no rollback (VM already down).
- [X] T016 [US2] **(owner-run — Vercel dashboard)** Add `valerio.dev` + `www.valerio.dev` to the
      project; mark `valerio.dev` primary; set `www.valerio.dev` "Redirect to" the apex (301)
- [X] T017 [US2] **(owner-run — DNS registrar)** Set apex `A → <IP from Vercel Domain settings>` and
      `www CNAME → <project>.vercel-dns-###.com` (exact values from the dashboard); lower TTL first
- [X] T018 [US2] Verify cutover: `dig A valerio.dev` matches the dashboard IP; `curl -sI
      https://valerio.dev/` → 200 + valid TLS; `curl -sI https://www.valerio.dev/` → 301 → apex
      (quickstart Scenario 4 / SC-004, SC-005, FR-006, FR-007)

**Checkpoint**: the live site is restored on `valerio.dev` via Vercel.

---

## Phase 5: User Story 3 — retire the manual VM stack (Priority: P3)

**Goal**: remove the dead deploy machinery + retired Makefile targets and update docs. **Only after
US2 is verified.** (VM already powered down — no decommission step.)

**Independent Test**: no `webserver`/`certbot`/`nginx` targets remain; docker-compose/config gone;
`make page` / `make lint` / `make dev-build` / `npm start` still work (quickstart Scenario 5).

- [X] T019 [P] [US3] Remove `docker-compose.yml` (app-builder + nginx + certbot services) and
      `config/nginx/`
- [X] T020 [US3] Remove the retired deploy targets from `Makefile` (`webserver*`, `certificates*`,
      `logs-*`, `remove-*`, `build`, `down`, `all`); keep `clean`, `dev`, `page`, `lint`,
      `lint-fast`, `dev-build`, `deploy`
- [X] T021 [US3] Decouple `Dockerfile` + `make dev-build` from the removed docker-compose so the
      no-local-node build still works (FR-011)
- [X] T022 [P] [US3] Remove the dead `predeploy` (gh-pages) script from `package.json`
- [X] T023 [US3] Verify retirement (quickstart Scenario 5): retired targets gone; `make page`,
      `make lint`, `make dev-build`, `npm start` all still work (FR-010, FR-011)

**Checkpoint**: only the Vercel deploy path remains; local dev intact.

---

## Phase 6: Polish & docs sync

**Purpose**: bring all docs in line with the new model (constitution Principle III) and final-verify.

- [X] T024 [P] Rewrite `docs/ci-cd.md`: CD is now GitHub Actions → Vercel prebuilt deploy; remove
      the manual VM/nginx/certbot deploy sections
- [X] T025 [P] Update `docs/architecture.md`: replace the nginx/certbot/app-builder "deploy stack"
      description with Vercel hosting
- [X] T026 [P] Update `README.md`: replace the GitHub Pages / `npm run deploy` + VM instructions with
      the Vercel push-to-deploy model; refresh usage/badges
- [X] T027 [P] Update `AGENTS.md`: Overview + Building/Deploy sections → Vercel CD (retire the
      manual-deploy language)
- [X] T028 Add an ADR in `docs/adr/` recording the decision: build in CI + deploy prebuilt to Vercel
      (not native Vercel build), apex-canonical, and vendored fonts (#24)
- [X] T029 Final verification: run through `quickstart.md` Scenarios 1–5 and `make lint`
      (Super-Linter) green (SC-006, SC-007)

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (Phase 1)**: owner-run; no code dependencies. Do before US1's workflow can deploy.
- **Foundational (Phase 2)**: **blocks US1** — the build must be reproducible/offline first.
- **US1 (Phase 3)**: after Setup + Foundational.
- **US2 (Phase 4)**: **after US1** (needs a working production deploy to cut over to).
- **US3 (Phase 5)**: **after US2 verified** (retire the VM stack only once Vercel is authoritative).
- **Polish (Phase 6)**: after the stories it documents (ci-cd/architecture/README/AGENTS + ADR).

### Sequentiality note

Unlike a typical multi-story feature, US1 → US2 → US3 must proceed **in order** (each depends on the
prior being live/verified). Within a phase, `[P]` tasks touch different files and can run together.

### Parallel opportunities

- **Phase 2**: T003, T004, T005 (three independent vendored dependencies) in parallel; then T006–T008.
- **Phase 5**: T019 and T022 in parallel.
- **Phase 6**: T024–T027 (four independent doc files) in parallel.

---

## Implementation strategy

### MVP (US1)

1. Phase 1 Setup (owner credentials + disconnect Git) → 2. Phase 2 Foundational (reproducible build)
→ 3. Phase 3 US1 (vercel.json + workflow + `make deploy`) → **validate**: PR preview + prod deploy
serve HTML + PDF. This is the deployable MVP — the site builds and serves on Vercel (on the
`*.vercel.app` URL) even before the custom-domain cutover.

### Incremental delivery

US1 (builds/serves) → US2 (domain cutover — site live on `valerio.dev`) → US3 (retire the VM stack) →
Polish (docs + ADR). Each increment is independently verifiable via its quickstart scenario.

---

## Notes

- `[P]` = different files, no dependency on an incomplete task.
- Owner-run tasks (T001, T002, T016, T017) happen in the Vercel dashboard / DNS registrar and are not
  repo edits — the agent cannot perform them.
- Each task ≥10 reviewable lines triggers the self-review gate (`/code-review`) before its PR.
- Commit per task or logical group; keep docs in sync in the same PR (Principle III).
