# AGENTS.md

## Overview

Personal CV / résumé site for Bruno Valério, hosted at <https://valerio.dev>. It's a small
Node.js static-site generator: CV content lives in a JavaScript data file, is rendered through
Handlebars into a single HTML page, and a matching PDF is produced with Playwright. The output is
served as static files behind nginx (Docker Compose) with Let's Encrypt TLS via certbot. CI is
lint-only (Super-Linter); deployment is manual.

## Architecture

- **Build pipeline (`src/build.js`)** — reads content from `src/metadata/metadata.js`, compiles
  `src/templates/index.html` with Handlebars, writes `dist/index.html`, copies `src/assets/` into
  `dist/`, then renders the PDF via `src/utils/pdf.js` (headless Chromium via Playwright).
- **Content vs. presentation** — edit CV content (name, title, facts, skills, experience) in
  `src/metadata/metadata.js`. Page markup is in `src/templates/index.html`; styling in
  `src/assets/styles.css`. Markdown inside content fields is rendered by
  `src/utils/helpers/markdown.js`.
- **Output** — everything is generated into `dist/` (gitignored). Never hand-edit `dist/`.
- **Deploy stack (`docker-compose.yml`)** — `app-builder` builds into a shared `html` volume;
  `webserver` is nginx serving that volume (config in `config/nginx/`); `certbot` /
  `certbot-dry-run` issue Let's Encrypt certs for `valerio.dev` + `www.valerio.dev`.

## Building and Running

**Always interact with this repo through the `Makefile`.** Before running an ad-hoc `npm`,
`docker`, or `docker compose` command, check the `Makefile` for a target that already does the job
and run that instead — the targets encode the correct flags, container names, volumes, and step
ordering. The targets are commented; read the `Makefile` to find the right one. The only common
task not wrapped by a target is the local watch dev server (`npm start`).

- **Dev Container (recommended)** — open `.devcontainer/` (`devcontainer up` or VS Code "Reopen in
  Container") for a reproducible environment with Node 22, the Playwright Chromium, Docker access,
  and Python + uv; every target below works inside it. It runs as `root` with host Docker access.
- `npm start` — build + watch + live-server dev server (needs node/npm locally).
- `make page` — one-off local build into `dist/` (needs node/npm).
- `make dev-build` — dockerized build that copies output into local `dist/` (no local node needed).
- `make build` — dockerized build into the shared `html` volume (used for deploy).
- The Docker build uses `node:22-bookworm-slim` and Playwright's version-pinned Chromium; local
  builds use your system Node.

Deploy is **manual**:

- `make webserver` — start nginx.
- `make webserver-upgrade-to-https` — issue certs, enable SSL config, reload nginx.
- `make all` — first-time full build + serve + HTTPS. Recreates certs — do **not** use for routine
  content updates.

## Testing Instructions

- There are **no** unit or integration tests in this repo.
- **Validate locally before pushing.** Run `make lint` before opening or updating a PR — it runs
  the *same* Super-Linter image CI uses (linting is the only CI gate), so you catch failures
  locally instead of waiting on the push-and-wait PR cycle. See [`docs/ci-cd.md`](docs/ci-cd.md)
  for details and caveats.
- Linting via Super-Linter runs on every push/PR (`.github/workflows/superlinter.yml`); `make lint`
  reproduces it locally.
- The Vercel deploy-preview check runs server-side and is **not** reproduced by `make lint`; it can
  only be validated after pushing.
- Enabled linters (`config/lint/super-linter.env`): JavaScript (`standard` style), CSS
  (stylelint + `stylelint-config-standard`), HTML, Dockerfile (hadolint), JSON, YAML, Markdown,
  XML, and GitHub Actions. `src/templates/*` is excluded from linting.
- After content or template changes, run `make page` and open `dist/index.html` to verify both the
  HTML and the generated PDF render correctly.

## Self-review (required for changes over 10 lines)

After a change touching **more than 10 reviewable lines** (excluding generated files such as
`package-lock.json` and `dist/`), and before reporting it done or opening a PR, run an independent
self-review and act on it:

- Invoke `/code-review`. It fans out fresh reviewer agents that critique the diff adversarially
  (correctness, removed behavior, robustness), then verify findings. Independence is the point —
  reviewers must not be anchored to the code as written.
- Fix confirmed findings; state explicitly anything you deliberately defer.

This is enforced by a `Stop` hook (`.claude/hooks/review-gate.sh`) that blocks finishing until the
current diff is recorded as reviewed. After reviewing, record it (the block message prints the
exact command): `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh" record`.

## Keep docs in sync

When a change alters behavior, commands, architecture, or workflow, update the relevant docs in the
**same PR** — `docs/` (`architecture.md`, `ci-cd.md`, `contributing.md`), the root `README.md`, and
this `AGENTS.md`. A change that outdates a doc isn't done until the doc is fixed. Record
significant, expensive-to-reverse decisions as an ADR in [`docs/adr/`](docs/adr/).

## Issue Tracking

Work is tracked in **GitHub Issues, Milestones, and Projects** — see
[`docs/contributing.md`](docs/contributing.md). Before starting non-trivial work, raise an issue
with a clear imperative title, a type label (`documentation` / `enhancement` / `bug` /
`maintenance`), and a body covering **Context**, an **Acceptance criteria** checklist, and
**References**. Group related issues under a milestone, and link PRs to issues with `Closes #<n>`.

## Required Skills

- This is a small JavaScript/Node project with no language-specific required skills.
- JavaScript follows `standard` style and CSS follows `stylelint-config-standard`, both enforced by
  Super-Linter (see [`docs/ci-cd.md`](docs/ci-cd.md)).

## Security

- Never commit credentials — use environment variables or secure secret management.
- Ensure `.env`, `.env.local`, and `.envrc` are in `.gitignore`.
- Let's Encrypt enforces strict rate limits. Always test certificate changes with
  `make certificates-dry-run` before running `make certificates` / `make webserver-upgrade-to-https`,
  or you risk being temporarily blocked from issuing certs.
- No application secrets are stored in the repo; the certbot email (`bruno@valerio.dev`) in
  `docker-compose.yml` is intentionally public.
