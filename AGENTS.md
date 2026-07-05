# AGENTS.md

## Overview

Personal CV / résumé site for Bruno Valério, hosted at <https://valerio.dev>. It's a small
Node.js static-site generator: CV content lives in a JavaScript data file, is rendered through
Handlebars into a single HTML page, and a matching PDF is produced with Playwright. The output is
served as static files on Vercel with automatic, auto-renewing TLS. CI lints every change
(Super-Linter) and prebuilds the Dev Container image (published to GHCR); CD builds in GitHub Actions
and deploys the prebuilt output to Vercel on every push (production from `main`, a preview per PR).

## Architecture

- **Build pipeline (`src/build.js`)** — reads content from `src/metadata/metadata.js`, compiles
  `src/templates/index.html` with Handlebars, writes `dist/index.html`, copies `src/assets/` into
  `dist/`, then renders the PDF via `src/utils/pdf.js` (headless Chromium via Playwright).
- **Content vs. presentation** — edit CV content (name, title, facts, skills, experience) in
  `src/metadata/metadata.js`. Page markup is in `src/templates/index.html`; styling in
  `src/assets/styles.css`. Markdown inside content fields is rendered by
  `src/utils/helpers/markdown.js`.
- **Output** — everything is generated into `dist/` (gitignored). Never hand-edit `dist/`.
- **Deploy (`.github/workflows/deploy.yml` + `vercel.json`)** — GitHub Actions builds `dist/`
  (Node 22 + pinned Playwright), then `make deploy` deploys the prebuilt output to Vercel:
  production from `main`, a preview per PR, with Vercel-managed TLS. `valerio.dev` is canonical;
  `www` 301-redirects to it.

## Building and Running

**Always interact with this repo through the `Makefile`.** Before running an ad-hoc `npm`,
`docker`, or `docker compose` command, check the `Makefile` for a target that already does the job
and run that instead — the targets encode the correct flags, container names, volumes, and step
ordering. The targets are commented; read the `Makefile` to find the right one. The only common
task not wrapped by a target is the local watch dev server (`npm start`).

- **Dev Container (recommended)** — `make dev` (or VS Code "Reopen in Container") opens
  `.devcontainer/`, a reproducible environment with Node 22, the Playwright Chromium, Docker access,
  Python + uv, the spec-kit `specify` CLI, and the `gh` + Claude Code CLIs; every target below works
  inside it. It runs as `root` with host Docker access, and `.claude/settings.json` pre-approves
  common read-only commands (`gh run watch`, `make --dry-run`, `make lint-fast`) to cut agent
  permission prompts. Full guide: [`docs/local-development.md`](docs/local-development.md).
- **Builds and PDF rendering run in the Dev Container or CI, not the host** — the pinned Playwright
  Chromium lives there. `make page-container` runs a one-off build inside the container (host stays
  clean); prefer it over a host build.
- `make page-container` — build inside the Dev Container (`devcontainer up` + `exec make page`).
- `npm start` — build + watch + live-server dev server (needs node/npm locally).
- `make page` — one-off build using your host toolchain (needs host node/npm + a Chromium).
- `make dev-build` — dockerized build (root `Dockerfile`, no compose) that copies output into local
  `dist/` (no local node needed).
- The Docker build uses `node:22-bookworm-slim` and Playwright's version-pinned Chromium; local
  builds use your system Node.

Deploy is **automatic** — see [`docs/ci-cd.md`](docs/ci-cd.md):

- Push to `main` → GitHub Actions builds and deploys **production** to Vercel (aliased to
  `valerio.dev`).
- Every PR → a **preview** deploy; its URL is posted to the PR.
- `make deploy` wraps the Vercel CLI (`vercel build` + `vercel deploy --prebuilt`); CI runs it — you
  rarely invoke it by hand.

## Testing Instructions

- The automated test gate is **visual-regression + PDF-render** (Playwright), not a unit/integration
  suite: `tests/visual.spec.js` snapshots the page at the six Bootstrap breakpoints against committed
  baselines (`tests/__screenshots__/`), and `tests/pdf.spec.js` asserts the build produced a valid
  PDF. It runs as a **required PR check** (`.github/workflows/visual.yml`, name `Visual + PDF checks`)
  alongside linting.
- **Validate locally before pushing.** During iteration use `make lint-fast` (fast native JS +
  Markdown lint) and/or the Dev Container's editor extensions; before opening/updating a PR run both
  `make lint` (the *same* Super-Linter image CI uses) and `make visual` (Playwright in the pinned
  image), so you catch lint and rendering failures locally instead of on the push-and-wait PR cycle.
  See [`docs/ci-cd.md`](docs/ci-cd.md) for details and caveats.
- **Visual baselines:** `make visual` checks the current render against the committed baselines; when
  a change *intentionally* alters the page, regenerate them with `make visual-update` and commit the
  updated PNGs (a reviewed step). Both run in the pinned Playwright image
  (`mcr.microsoft.com/playwright:v1.61.1-noble`) so local rendering matches CI — the #1 snapshot flake
  is cross-environment font rendering.
- Linting via Super-Linter runs on every push/PR (`.github/workflows/superlinter.yml`); `make lint`
  reproduces it locally — including on Apple Silicon (it runs the amd64 image emulated) and from a
  `make worktree` sibling. On arm64 it skips the GitHub Actions validator (actionlint segfaults under
  emulation); run `make lint-actions` (native `actionlint`) to check workflow files there.
- The Vercel deploy-preview check runs server-side and is **not** reproduced by `make lint`; it can
  only be validated after pushing.
- Changes under `.devcontainer/**` (or `package.json` / `package-lock.json`) also trigger the **Dev
  Container** prebuild workflow (`.github/workflows/devcontainer.yml`): it builds the image and runs
  `make page` as a smoke test on the PR, then publishes it to GHCR on merge to `main`. Not
  reproduced by `make lint`. See [`docs/ci-cd.md`](docs/ci-cd.md).
- Enabled linters (`config/lint/super-linter.env`): JavaScript (`standard` style), CSS
  (stylelint + `stylelint-config-standard`), HTML, Dockerfile (hadolint), JSON, YAML, Markdown,
  XML, GitHub Actions, and Bash (shellcheck). Excluded from linting: `src/templates/*` (Handlebars),
  `.specify/` (vendored spec-kit scripts), and `.claude/skills/`.
- After content or template changes, build (`make page-container`, or `make page` if you already
  have the host toolchain) and open `dist/index.html` to verify both the HTML and the generated PDF
  render correctly.

## Self-review (required for changes over 10 lines)

After a change touching **more than 10 reviewable lines** (excluding generated files such as
`package-lock.json` and `dist/`), and before reporting it done or opening a PR, run an independent
self-review and act on it:

- Invoke `/code-review`. It fans out fresh reviewer agents that critique the diff adversarially
  (correctness, removed behavior, robustness), then verify findings. Independence is the point —
  reviewers must not be anchored to the code as written.
- Fix confirmed findings; state explicitly anything you deliberately defer.

This is enforced by a `Stop` hook (`.claude/hooks/review-gate.sh`) that blocks finishing until the
current diff is recorded as reviewed. The gate is worktree-aware: it measures each worktree you
edited this turn (plus the current directory's) and records/clears each by its own root, so it fires
for work done in a `make worktree` sibling — not just the main checkout. After reviewing, record it
with the command the block message prints (it names the worktree):
`bash "$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh" record "<worktree>"`.

## Keep docs in sync

When a change alters behavior, commands, architecture, or workflow, update the relevant docs in the
**same PR** — `docs/` (`architecture.md`, `ci-cd.md`, `contributing.md`), the root `README.md`, and
this `AGENTS.md`. A change that outdates a doc isn't done until the doc is fixed. Record
significant, expensive-to-reverse decisions as an ADR in [`docs/adr/`](docs/adr/).

## Improving the harness

The **harness** — this `AGENTS.md`, the constitution, `docs/`, `.claude/` (hooks, settings, skills),
the Dev Container, CI, and the spec-kit setup — is a living system. When resolving a task reveals a
**systemic gap** in it (a missing convention, an undocumented assumption, or a footgun likely to
recur — e.g. builds must run in the Dev Container not the host, or Dev Container deps not persisting),
don't just patch it ad-hoc:

- **Name the gap and ask** whether to codify the fix into the harness — prefer fixing the system over
  the symptom. Whether to codify now, defer, or skip is the owner's call.
- **Prefer a gate over a doc.** A documented best practice relies on a fallible human or agent
  remembering it at the right moment; a **deterministic gate** (a test, validation, lint rule, hook,
  or CI check that mechanically passes or fails) does not. For a **costly or recurring** mistake, the
  fix to reach for is a gate that makes the wrong thing fail loudly and automatically. Documentation
  alone is never the final answer: it's a stopgap only when a gate is genuinely impractical, and then
  it ships *with* a filed issue to add the gate. This is **Principle VII** of the
  [constitution](.specify/memory/constitution.md).
- **A near-miss caught only by inspection means a gate is missing.** If you (or a review) catch a real
  problem by eye that no gate would have caught, the catch is not the fix — closing the gap with a gate
  is. File it.
- **If the owner agrees**, raise a `harness`-labeled issue (see
  [`docs/contributing.md`](docs/contributing.md)) and handle it as its own change, separate from the
  task that surfaced it. `harness` is a grouping **label, not a milestone** — this work is ongoing.

Surface such gaps proactively rather than waiting to be asked.

## Issue Tracking

Work is tracked in **GitHub Issues and Milestones** (Projects optional) — see
[`docs/contributing.md`](docs/contributing.md). Before starting non-trivial work, raise an issue
with a clear imperative title, a type label (`documentation` / `enhancement` / `bug` /
`maintenance`), and a body covering **Context**, an **Acceptance criteria** checklist, and
**References**. Use **one milestone per shippable thing** (a deliverable/initiative) and **labels to
tag phases** (e.g. `phase:*`) for grouping within it — not a milestone per phase. A GitHub **Project
is optional** (a board/field view; use it for kanban/custom-field/cross-milestone tracking). Link
PRs to issues with `Closes #<n>`. Start each branch in its own git worktree off fresh `origin/main`
with `make worktree name=<b>` — never off a stale local `main`. `make worktree` first prunes
worktrees whose PR has merged (and `make worktree-prune` does it on demand), so merged worktrees
clean themselves up.

## Spec-driven development

Non-trivial features are developed spec-first with spec-kit: `/speckit-specify` → `/speckit-clarify`
→ `/speckit-plan` → `/speckit-tasks` → `/speckit-taskstoissues` → `/speckit-implement` (skills under
`.claude/skills/`). The spec lives in `specs/<feature>/` as the source of intent; the project
constitution is `.specify/memory/constitution.md`. See [`docs/spec-driven.md`](docs/spec-driven.md).

**Task status lives in GitHub Issues, not `tasks.md`.** `/speckit-taskstoissues` turns each task into
an issue *and* repurposes its `tasks.md` checkbox into a link to that issue
(`- [ ] T001 …` → `- [T001](…/issues/12) …`); thereafter `tasks.md` is the decomposition + issue map,
completion is the linked issue closing via `Closes #<n>`, and the milestone progress bar is the
status view — `/speckit-implement` does not tick checkboxes. `/speckit-taskstoissues` also scopes its
issues per feature: the canonical issue title is prefixed with the feature number (`003-T001: …`) and
dedup matches that feature-scoped id, so per-feature task IDs (which restart at `T001` each feature)
don't collide with prior features' `T001…` issues. (These are local customizations to the vendored
spec-kit skills; re-apply them if the skills are ever re-synced from upstream.)

## Required Skills

- This is a small JavaScript/Node project with no language-specific required skills.
- JavaScript follows `standard` style and CSS follows `stylelint-config-standard`, both enforced by
  Super-Linter (see [`docs/ci-cd.md`](docs/ci-cd.md)).

## Security

- Never commit credentials — use environment variables or secure secret management.
- Ensure `.env`, `.env.local`, and `.envrc` are in `.gitignore`.
- TLS is managed by Vercel (automatic issuance + renewal) — there are no certificates to handle in
  this repo.
- The only deploy secret is `VERCEL_TOKEN` (plus `VERCEL_ORG_ID` / `VERCEL_PROJECT_ID` variables),
  configured in GitHub repo settings and consumed by `.github/workflows/deploy.yml` — never committed.
  No application secrets are stored in the repo.
