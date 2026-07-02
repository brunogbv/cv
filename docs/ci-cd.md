# CI/CD

CI lints every change and prebuilds the Dev Container image. CD is automated: GitHub Actions builds
the site and deploys the prebuilt output to **Vercel** on every push — production from `main`, a
preview per PR — with Vercel-managed TLS. There is no manual server or certificate step.

## Continuous Integration — GitHub Actions

Three workflows: **`.github/workflows/superlinter.yml`** (name: `Lint`) lints every change,
**`.github/workflows/devcontainer.yml`** (name: `Dev Container`) prebuilds the Dev Container image
(see [Dev Container image prebuild](#dev-container-image-prebuild)), and
**`.github/workflows/deploy.yml`** (name: `Deploy`) builds and deploys the site to Vercel (push to
`main` → production, `pull_request` → preview; see [Continuous Deployment](#continuous-deployment--vercel)).
The lint workflow:

- **Triggers:** every `push` and every `pull_request`.
- **Runner:** `ubuntu-latest`.
- **Steps:**
  1. Checkout with `fetch-depth: 0` — Super-Linter needs full git history to diff changed files.
  2. Load `config/lint/super-linter.env` into `$GITHUB_ENV`.
  3. Run `super-linter/super-linter@v6.7.0`, reporting results as GitHub status checks
     (`permissions: statuses: write`, using the default `GITHUB_TOKEN`).
- A Super-Linter status badge is shown at the top of the root [`README.md`](../README.md).

There are **no automated tests** for the site — linting is the gate on site changes. Site build +
deploy runs in CI via the `Deploy` workflow ([below](#continuous-deployment--vercel)); the Dev
Container workflow builds and smoke-tests the *dev-environment* image (not the site itself).

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

Linting is fully reproducible locally — run it before opening or updating a PR to get feedback in one
pass instead of the push-and-wait cycle:

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

## Continuous Deployment — Vercel

`.github/workflows/deploy.yml` (name: `Deploy`) is the **sole deploy path** — Vercel's own git build
is disabled via `vercel.json` → `git.deploymentEnabled: false`. It builds `dist/` in CI (Node 22 +
the lockfile-pinned Playwright Chromium, then `make page`) and deploys the prebuilt output with
**`make deploy`** (`vercel pull` → `vercel build` → `vercel deploy --prebuilt`). Push to `main`
deploys `--prod` (aliased to `valerio.dev`); a `pull_request` deploys a preview whose URL is posted
back to the PR. `framework: null` + `buildCommand: ""` in `vercel.json` make `vercel build` package
the existing `dist/` instead of re-running the Node build. TLS for `valerio.dev` + `www.valerio.dev`
is provisioned and renewed automatically by Vercel; `www` 301-redirects to the apex.

If `make page` fails (including a PDF render error) the job fails **before** any deploy, so a broken
build never publishes — the last good production deployment keeps serving.

- **Cache headers** (in `vercel.json`): HTML + PDF are edge-cached (`s-maxage=86400`) and static
  assets long-lived (`s-maxage=31536000`), all with client `max-age=0` so browsers revalidate; plus
  `X-Content-Type-Options` / `X-Frame-Options` / `Referrer-Policy` security headers. Vercel strips
  the edge-only `s-maxage` / `stale-while-revalidate` from client responses.
- **Configuration (GitHub repo settings):** secret `VERCEL_TOKEN` and variables `VERCEL_ORG_ID` /
  `VERCEL_PROJECT_ID`; the project's Vercel Git integration is disconnected so this workflow is the
  only deploy trigger.

### Domain cutover (DNS runbook)

The one-time DNS cutover of `valerio.dev` + `www.valerio.dev` from the GCP VM to Vercel — **performed
2026-07-02**, kept here as a reference. There was no rollback target or downtime window to protect
(the VM was already off), so it simply **restored** availability. The steps, in order:

**1. Prepare (before touching DNS)**

- **Verify serving first.** Merge to `main` (the `Deploy` workflow deploys `--prod`) and confirm the
  production deployment renders: open its `*.vercel.app` URL **in a browser** and check the page
  **and** the PDF render with the correct fonts. The production **TLS certificate** can't be verified
  yet — Vercel issues it only after DNS points at Vercel (that check is step 4).
- **⚠️ Check Deployment Protection** (Vercel → Project → Settings → Deployment Protection) — a hard
  blocker. It must **not** protect production (set it to *Only Preview Deployments*, or off), or
  `valerio.dev` is auth-walled (`302` → Vercel SSO) after cutover and the public CV is unreachable.
  Preview URLs staying protected is expected — which is also why a `curl` of a `*.vercel.app` URL
  returns `302` while protection is on, so verify serving in a browser (above) rather than with curl.
- **Lower the DNS TTL.** Check the current TTL on the apex `A` and `www` records at the registrar
  (e.g. 3600s), lower it (e.g. to 300s), and wait at least the *old* TTL so cached records expire —
  then the cutover propagates quickly.

**2. Add the domains in Vercel (owner, dashboard)**

- Add `valerio.dev` and `www.valerio.dev` to the project.
- Mark `valerio.dev` as the **primary** (canonical) domain.
- Set `www.valerio.dev` to **Redirect to** `valerio.dev` (`301`).
- Vercel then shows the exact records to set — an apex `A` IP and a `www` `CNAME` target. Use those
  dashboard values, not the examples below (they vary by project).

**3. Point DNS (owner, registrar)**

- Apex: `A → 216.198.79.1` (use the exact IP shown in Vercel Domain settings).
- `www`: `CNAME → <hash>.vercel-dns-###.com` (exact target from the dashboard).
- TLS is provisioned and renewed automatically by Vercel once DNS resolves to it — no certbot, no
  manual renewal. The certificate is issued after DNS points at Vercel; verify it in step 4.
- Leave `MX` and `TXT` (SPF, DKIM/`_domainkey`, verification) records untouched — web (`A`/`CNAME`)
  and email are independent.

**4. Verify the cutover**

```sh
dig A valerio.dev +short              # matches the A record shown in Vercel Domain settings
curl -sI https://valerio.dev/         # 200, valid TLS; client Cache-Control: public, max-age=0
                                      #   (edge-only s-maxage / stale-while-revalidate are stripped)
curl -sI https://www.valerio.dev/     # 301 -> https://valerio.dev/
```

Vercel issues the certificate a few minutes after DNS points at it, so a TLS error on the first
`curl` is normal — wait a few minutes and retry. Once the checks pass, load `https://valerio.dev/`
in a browser and confirm the page and `/<slug>.pdf` render correctly over HTTPS, then restore a
normal TTL.
