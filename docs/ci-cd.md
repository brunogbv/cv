# CI/CD

CI is automated: it lints every change, prebuilds the Dev Container image, and (as of the in-progress
Vercel migration) builds and deploys the site to Vercel. **Site CD is mid-migration:** the Vercel
pipeline (`deploy.yml`, below) is live, but production traffic still hits the manually-operated GCP
VM until the DNS cutover — so the manual `make` deploy targets remain authoritative for now. The full
rewrite of this deploy section lands with the migration's Polish phase.

## Continuous Integration — GitHub Actions

Three workflows: **`.github/workflows/superlinter.yml`** (name: `Lint`) lints every change,
**`.github/workflows/devcontainer.yml`** (name: `Dev Container`) prebuilds the Dev Container image
(see [Dev Container image prebuild](#dev-container-image-prebuild)), and
**`.github/workflows/deploy.yml`** (name: `Deploy`) builds and deploys the site to Vercel (push to
`main` → production, `pull_request` → preview; see [Deploy to Vercel](#deploy-to-vercel)). The lint
workflow:

- **Triggers:** every `push` and every `pull_request`.
- **Runner:** `ubuntu-latest`.
- **Steps:**
  1. Checkout with `fetch-depth: 0` — Super-Linter needs full git history to diff changed files.
  2. Load `config/lint/super-linter.env` into `$GITHUB_ENV`.
  3. Run `super-linter/super-linter@v6.7.0`, reporting results as GitHub status checks
     (`permissions: statuses: write`, using the default `GITHUB_TOKEN`).
- A Super-Linter status badge is shown at the top of the root [`README.md`](../README.md).

There are **no automated tests** for the site — linting is the gate on site changes. Site build +
deploy now runs in CI via the `Deploy` workflow ([below](#deploy-to-vercel)); the Dev Container
workflow builds and smoke-tests the *dev-environment* image (not the site itself).

### Linter configuration

Defined in `config/lint/super-linter.env`:

| Setting                          | Value / effect                                                  |
| -------------------------------- | --------------------------------------------------------------- |
| `DEFAULT_BRANCH`                 | `main`                                                          |
| `FILTER_REGEX_EXCLUDE`           | Skips `src/templates/*` (Handlebars), `.specify/` (vendored spec-kit scripts), and `.claude/skills/`. |
| `IGNORE_GITIGNORED_FILES`        | `true`                                                          |
| `LINTER_RULES_PATH`              | `config/lint`                                                   |
| Enabled validators               | Bash (shellcheck), CSS, Dockerfile (hadolint), GitHub Actions, HTML, JavaScript (`standard`), JSON, JSX, Markdown, TypeScript (`standard`), XML, YAML |

JavaScript is checked against the **`standard`** style; CSS uses `stylelint` with
`stylelint-config-standard` (declared in `package.json`). Shell scripts are checked with
**shellcheck** (`VALIDATE_BASH`); the vendored spec-kit scripts under `.specify/` are excluded (we
don't own them and they don't pass), so only repo-owned scripts (`scripts/`, `.claude/hooks/`) are
gated. `shfmt` formatting is intentionally not enabled — its style conflicts with the scripts'
hand-written layout, and shellcheck already covers correctness.

### Validate locally before pushing

Linting is the only CI gate, and it is fully reproducible locally — run it before opening or
updating a PR to get feedback in one pass instead of the push-and-wait cycle:

```sh
make lint
```

This runs the **same** Super-Linter image CI pins (`v6.7.0`) in Docker with `RUN_LOCAL=true`, using
`config/lint/super-linter.env`, so a local pass closely matches the CI result. It works on Apple
Silicon (the image is amd64-only, so the target runs it via `--platform linux/amd64`) and from a
`make worktree` sibling (the target also bind-mounts the shared git dir — a worktree's `.git` is a
file pointing at the main checkout — so Super-Linter can resolve `main`).

For a quicker inner-loop check, `make lint-fast` runs just the JavaScript (`standard`) and Markdown
(`markdownlint`) linters natively — no Docker, no full image — calibrated to approximate CI's
behavior for those file types (`make lint` is the exact mirror). The Dev Container also installs editor extensions (markdownlint, StandardJS,
Stylelint, Hadolint, YAML) for live in-editor feedback. `make lint` remains the authoritative
CI-parity check.

Caveats:

- **Apple Silicon:** Super-Linter ships no arm64 image, so `make lint` runs it under emulation
  (`--platform linux/amd64`) — correct, but slower than native. Under that emulation the
  `GITHUB_ACTIONS` validator (actionlint) crashes with a SIGSEGV, so `make lint` **skips it on
  arm64** (and says so); check workflows with **`make lint-actions`**, which runs actionlint natively
  (pinned to the version Super-Linter bundles). On amd64 (CI/Intel) nothing is skipped. `make
  lint-fast` stays the quick inner-loop check.
- **Scope:** locally, Super-Linter lints the whole workspace; in CI it lints only files changed
  against `main`. Local is broader, not narrower.
- **Vercel:** the deploy-preview check runs on Vercel's side and is **not** covered by `make lint`;
  it can only be validated after pushing.

### Dev Container image prebuild

`.github/workflows/devcontainer.yml` (name: `Dev Container`) prebuilds the Dev Container image and
publishes it to the GitHub Container Registry (GHCR), so `devcontainer up` — on any machine and in
each `make worktree` — pulls cached layers instead of building the image from scratch.

- **Triggers:** `push` to `main` and `pull_request`, both filtered to the paths that determine the
  image (`.devcontainer/**`, `package.json`, `package-lock.json`, and the workflow file); plus
  manual `workflow_dispatch`.
- **What it does:** logs in to GHCR (`docker/login-action`, `packages: write` + `GITHUB_TOKEN`),
  then `devcontainers/ci@v0.3` builds the image (Dockerfile + features), runs the container
  lifecycle (`postCreate`: `npm ci` + `playwright install`), and runs **`make page`** inside it as a
  smoke test that the image renders the HTML page and the PDF.
- **Publish vs. build-only:** `push: filter` publishes the image
  (`ghcr.io/brunogbv/cv-devcontainer:latest`) **only on pushes to `main`**. Pull requests and manual
  `workflow_dispatch` runs build and smoke-test the image but do **not** publish — so a broken
  Dockerfile is caught at PR time.
- **Consumption + fallback:** `devcontainer.json`'s `build.cacheFrom` points at the same GHCR image,
  so `devcontainer up` reuses the published layers (near-instant when unchanged). If the registry is
  unreachable or the image is missing, the build simply falls back to a normal local build — the
  prebuild is an optimization, never a hard dependency.

**One-time owner step (manual):** for anonymous pulls to work — so contributors get the cache
without a `docker login` — the GHCR package must be **public**. After the first publish from `main`,
set the `cv-devcontainer` package to Public once (GitHub → your Packages → `cv-devcontainer` →
Package settings → Change visibility → Public). Until then, only authenticated pulls hit the cache
and everyone else falls back to a local build (which still works, just slower).

### Deploy to Vercel

`.github/workflows/deploy.yml` (name: `Deploy`) is the incoming Vercel CD path (Vercel's own git
build is disabled via `vercel.json` → `git.deploymentEnabled: false`). It builds `dist/` in CI
(Node 22 + the lockfile-pinned Playwright Chromium, then `make page`) and deploys the prebuilt output
with **`make deploy`** (`vercel pull` → `vercel build` → `vercel deploy --prebuilt`). Push to `main`
deploys `--prod`; a `pull_request` deploys a preview whose URL is posted back to the PR.
`framework: null` + `buildCommand: ""` in `vercel.json` make `vercel build` package the existing
`dist/` instead of re-running the Node build.

- **Setup (owner, one-time):** repo secret `VERCEL_TOKEN` + variables `VERCEL_ORG_ID` /
  `VERCEL_PROJECT_ID`, and disconnect the project's Vercel Git integration. Until these exist the
  `Deploy` job fails at the `vercel` step (nothing is published).
- **Not yet authoritative:** production still serves from the GCP VM until the DNS cutover; see the
  manual stack below. This section is a stopgap — the full CD rewrite (and removal of the manual
  stack) lands with the migration's Polish phase.

## Continuous Deployment — manual, Docker-based

The site is self-hosted. Deployment is orchestrated by the `Makefile` and `docker-compose.yml`,
which define three services sharing two named volumes:

| Service           | Role                                                                 |
| ----------------- | -------------------------------------------------------------------- |
| `app-builder`     | Builds the site (the `Dockerfile` builder image) into the `html` volume. |
| `webserver`       | nginx serving the `html` volume on ports 80/443 (`config/nginx/`).   |
| `certbot` / `certbot-dry-run` | Issues Let's Encrypt certs for `valerio.dev` + `www.valerio.dev` into the `certs` volume. |

| Volume  | Purpose                                                              |
| ------- | ------------------------------------------------------------------- |
| `html`  | The built static site, shared by `app-builder`, `webserver`, `certbot`. |
| `certs` | `/etc/letsencrypt` — TLS certificates.                              |

### Deploy commands

```sh
make build                      # Build the site into the html volume (via app-builder)
make webserver                  # Start nginx (HTTP only)
make webserver-upgrade-to-https # Issue certs, swap to SSL config, reload nginx
make all                        # First-time only: build + serve + HTTPS (recreates certs!)
```

- `make all` is for a **first-time** stand-up. Avoid it for routine content updates because it
  recreates certificates.
- For a routine content update: `make build` to rebuild, then redeploy/reload the webserver.

### TLS / certbot

- `make certificates` runs certbot for real; `make certificates-dry-run` simulates issuance.
- **Let's Encrypt has strict rate limits.** Always validate with `make certificates-dry-run`
  before `make certificates` / `make webserver-upgrade-to-https`, or you can be temporarily
  blocked from issuing certs.
- `make webserver-upgrade-to-https` runs certbot, swaps nginx to the SSL site config
  (`valerio-ssl.conf`), and reloads nginx (`webserver-ssl-config` + `webserver-restart-nginx`).

### nginx configuration

The webserver image (`config/nginx/Dockerfile`, `nginx:alpine`) selects which site config to
enable via the `SITE_NAME` build arg, symlinking it into `sites-enabled/`. Three configs live in
`config/nginx/sites-available/`:

| Config               | Behavior                                                                                  |
| -------------------- | ----------------------------------------------------------------------------------------- |
| `valerio.dev`        | HTTP-only (pre-TLS). Serves the ACME challenge path and `/healthcheck`; `/` returns 404.  |
| `valerio-ssl.conf`   | Redirects HTTP → HTTPS; serves the site over 443 using the Let's Encrypt cert/key.        |
| `valerio-local.conf` | Same as `valerio.dev` but also matches `localhost`, for local testing.                    |

All variants expose `/healthcheck` (also used by the `webserver` healthcheck in
`docker-compose.yml`). The ACME challenge location is what lets certbot validate the domain over
HTTP before certs exist.

### Deployment flow

```text
make build ─▶ html volume ─▶ webserver (nginx :80, valerio.dev config, /healthcheck)
                                   │
                   make webserver-upgrade-to-https
                                   │
                   certbot (ACME challenge via :80) ─▶ certs volume
                                   │
                   swap to valerio-ssl.conf + reload ─▶ nginx :443 (HTTPS)
```

### Helpful operational targets

```sh
make logs-webserver       # nginx logs
make logs-app-builder     # build logs
make logs-certbot         # certbot logs
make down                 # stop the webserver (docker compose down)
make dev-build            # dockerized build, copied back into local ./dist
```
