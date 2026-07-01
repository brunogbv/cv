# Implementation Plan: Migrate hosting & CD to Vercel

**Branch**: `001-vercel-cd-migration` | **Date**: 2026-07-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-vercel-cd-migration/spec.md`

## Summary

Move hosting and CD off the manual GCP VM (nginx + certbot) to Vercel. The decisive constraint is
that the site's PDF is rendered at build time by headless Chromium, which does **not** run reliably
in Vercel's native build image. The plan therefore **builds the whole site (HTML + PDF) in GitHub
Actions using the repo's pinned Playwright Chromium — the environment that already works — and
deploys the prebuilt `dist/` to Vercel via the Vercel CLI** (`vercel build` / `vercel deploy
--prebuilt`), with Vercel's own git build disabled. This guarantees the PDF is rendered by the same
Chromium everywhere (reproducibility + parity), makes Vercel a pure static host/CDN/TLS/domain
provider, and folds in issue #24 (vendor fonts/CSS) so the CI build is deterministic offline.

## Technical Context

**Language/Version**: Node.js 22 (existing).

**Primary Dependencies**: Handlebars (templating), Playwright (headless Chromium for PDF),
`fs-extra`, `dayjs`, `speakingurl`. New: Vercel CLI (`vercel`, used in CI only). No new runtime deps
in the app (explicitly **not** adding `@sparticuz/chromium`).

**Storage**: N/A — static site; output is `dist/` (HTML + assets + PDF).

**Testing**: No unit tests (per constitution). Verification = `make lint` (Super-Linter, the CI
gate) + visual check of the generated HTML/PDF + the deploy quickstart.

**Target Platform**: Vercel (static hosting + CDN + automatic TLS + custom domains + preview
deployments). Build runs on GitHub Actions `ubuntu-latest`.

**Project Type**: Single project — static-site generator (see `AGENTS.md`).

**Performance Goals**: N/A beyond "loads fast" — edge-cached static assets. Build time target:
keep CI build+deploy under ~3 min (cache the Playwright browser).

**Constraints**:
- PDF must be byte-faithful to the local build → render with the lockfile-pinned Playwright
  Chromium, never a substitute binary.
- Build must succeed with **no external CDN access** (issue #24): vendor Roboto, Bootstrap 5.2.0,
  and Font Awesome 6.1.2 into `src/assets/` and reference them locally; drop reliance on
  `networkidle`; add an explicit `page.goto` timeout so a missing asset fails fast.
- DNS changes are owner-run at the registrar (outside the repo).
- Canonical host `valerio.dev` (apex); `www` 301-redirects to it.

**Scale/Scope**: One static page + one PDF; single maintainer; low traffic.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Assessment |
|-----------|------------|
| I. Makefile is the interface | **Pass (with action)** — the CI workflow invokes `make page` to build; a thin `make deploy` (wrapping `vercel deploy --prebuilt`) is added so the deploy command lives in the Makefile too. The retired VM targets are removed. No ad-hoc commands introduced. |
| II. Self-review before done | **Pass** — each implementation PR (>10 lines) runs `/code-review` + records the gate. |
| III. Docs stay in sync | **Pass (with action)** — `docs/ci-cd.md`, `docs/architecture.md`, `README.md`, `AGENTS.md` updated in the same PRs; an ADR records the "build in CI, deploy prebuilt to Vercel" decision. |
| IV. Validate locally; CI is the gate | **Pass** — `make page` validates the build locally (incl. offline); Super-Linter stays the lint gate; the deploy workflow is additive. |
| V. Reproducible and minimal | **Pass** — Strategy B keeps one pinned Chromium; no new runtime deps; vendored fonts remove network nondeterminism. |

No violations → Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-vercel-cd-migration/
├── plan.md              # This file
├── research.md          # Phase 0 — decisions & rationale
├── data-model.md        # Phase 1 — config/deploy entities
├── quickstart.md        # Phase 1 — end-to-end validation guide
├── contracts/
│   ├── serving-contract.md   # HTTP surface: routes, redirects, headers, TLS
│   └── deploy-contract.md    # CI → Vercel deploy interface
└── tasks.md             # Phase 2 — created by /speckit-tasks (not here)
```

### Source Code (repository root)

```text
vercel.json                      # NEW — outputDirectory=dist, git.deploymentEnabled=false,
                                 #       cleanUrls, cache-control + security headers
.github/workflows/
├── superlinter.yml              # unchanged — lint gate
└── deploy.yml                   # NEW — build (Node 22 + pinned Playwright) → vercel deploy --prebuilt
src/
├── build.js                     # EDIT — await buildPdf(); fail on PDF error
├── utils/pdf.js                 # EDIT — explicit timeout; drop networkidle reliance
├── templates/index.html         # EDIT — reference vendored fonts/CSS instead of CDNs (#24)
└── assets/
    └── vendor/                  # NEW — vendored Roboto, Bootstrap 5.2.0, Font Awesome 6.1.2 (#24)
Makefile                         # EDIT — remove VM/nginx/certbot targets; add `make deploy`
docker-compose.yml               # REMOVE (final phase) — app-builder/nginx/certbot services
config/nginx/                    # REMOVE (final phase)
Dockerfile                       # KEEP — repurposed as the standalone build image for `make dev-build` (FR-011)
package.json                     # EDIT — drop the dead `predeploy` (gh-pages) script
docs/{ci-cd,architecture}.md, README.md, AGENTS.md   # EDIT — new deploy model; remove stale gh-pages docs
docs/adr/000X-*.md               # NEW — ADR for the CI-build + prebuilt-deploy decision
```

**Structure Decision**: Single project, unchanged layout. Changes are additive config
(`vercel.json`, `deploy.yml`), a small source refactor (vendored assets + PDF await/timeout), and —
as the final phase — removal of the VM deploy stack.

## Phases (mapping to spec user stories)

- **Phase A — reproducible build + vercel config (US1 / P1)**: vendor fonts (#24), fix
  `pdf.js`/`build.js` (await + timeout), add `vercel.json`, add the `deploy.yml` workflow,
  configure Vercel project (disable git build, set secrets). Outcome: green preview deploys per PR
  and production deploys from `main`.
- **Phase B — domain cutover (US2 / P2)**: add `valerio.dev` + `www` to the Vercel project, set
  `www` → 301 → apex, owner updates DNS (A + CNAME), verify serving + TLS. Restores the live site.
- **Phase C — retire the VM stack (US3 / P3)**: remove `docker-compose.yml` (app-builder + nginx +
  certbot), `config/nginx/`, and the retired Makefile deploy targets (`webserver*`, `certificates*`,
  `logs-*`, `remove-*`, `build`, `down`, `all`). **Keep** the `Dockerfile` + `make dev-build` (the
  no-local-node build path — decouple it from the removed docker-compose so FR-011 holds). Rewrite
  the deploy docs (`docs/ci-cd.md`, `docs/architecture.md`, `README.md`, `AGENTS.md`) to the
  push-to-Vercel model, **including removing the stale GitHub Pages / `npm run deploy` instructions
  in `README.md` and the now-dead `predeploy` script in `package.json`**. (VM already powered down —
  no separate decommission.)

## Complexity Tracking

No constitution violations — no entries.
