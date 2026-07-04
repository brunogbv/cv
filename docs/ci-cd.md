# CI/CD

CI lints every change, runs a visual-regression + PDF-render gate, and prebuilds the Dev Container
image. CD is automated: GitHub Actions builds the site and deploys the prebuilt output to **Vercel**
on every push — production from `main`, a preview per PR — with Vercel-managed TLS. There is no
manual server or certificate step.

## Continuous Integration — GitHub Actions

Four workflows: **`.github/workflows/superlinter.yml`** (name: `Lint`) lints every change,
**`.github/workflows/visual.yml`** (name: `Visual`) runs the visual-regression + PDF-render gate (see
[Visual + PDF gate](#visual--pdf-gate)), **`.github/workflows/devcontainer.yml`** (name: `Dev
Container`) prebuilds the Dev Container image (see [Dev Container image prebuild](#dev-container-image-prebuild)),
and **`.github/workflows/deploy.yml`** (name: `Deploy`) builds and deploys the site to Vercel (push to
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

Site changes are gated by **two** required checks: linting (above) and the **visual-regression +
PDF-render** gate ([below](#visual--pdf-gate)) — there is no unit/integration suite. Site build +
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
`stylelint-config-standard` (both declared as devDependencies in `package.json`). In CI,
Super-Linter has no repo stylelint config, so it uses its own **bundled default**
(`{ "extends": "stylelint-config-standard" }`, resolved against the *image's* pinned
stylelint) — do **not** add a `config/lint/.stylelintrc.json`: Super-Linter would load it
and resolve `stylelint-config-standard` against the repo's *newer* `node_modules`, whose
rules the image's older bundled stylelint doesn't recognize, breaking the CSS check. The
native `make lint-fast` CSS step mirrors the same ruleset via `config/lint/stylelint-fast.json`
(deliberately *not* the auto-loaded filename — see [below](#validate-locally-before-pushing)).
Shell scripts are checked with
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

For a quicker inner-loop check, `make lint-fast` runs the JavaScript (`standard`), CSS (`stylelint`),
and Markdown (`markdownlint`) linters natively — no Docker, no full image — calibrated to approximate
CI's behavior for those file types (`make lint` is the exact mirror). The CSS step uses
`config/lint/stylelint-fast.json` (`{ "extends": "stylelint-config-standard" }`, the same base as
Super-Linter's bundled default) over the same file scope Super-Linter lints (`src/**/*.css` +
`tests/**/*.css`), so a CSS rule violation now fails `lint-fast` locally instead of only surfacing in
CI. Like `markdownlint-fast.json`, it's a `*-fast` config that **mirrors** the CI ruleset without being
picked up by CI: it's deliberately *not* named `.stylelintrc.json`, because that (Super-Linter's default
CSS config filename under `LINTER_RULES_PATH`) would make Super-Linter load it and resolve
`stylelint-config-standard` against the repo's newer `node_modules`, whose rules the image's older
bundled stylelint rejects. So local (`stylelint` 16 + config-standard 36) and CI (the image's bundled
older pair) share the same *base config* but run different *stylelint versions* — an approximation, not a
byte-for-byte mirror; `make lint` remains the exact CSS check. The Dev Container also installs editor
extensions (markdownlint, StandardJS, Stylelint, Hadolint, YAML) for live in-editor feedback. `make
lint` remains the authoritative CI-parity check.

#### Style conventions this repo trips on

The rules below have repeatedly bitten changes here; know them before writing CSS or Markdown so you
don't burn a lint round-trip. All are covered by `make lint-fast` (and `make lint`).

- **stylelint `selector-class-pattern`** — class names must be **kebab-case** (`.card-title`), lower
  case with hyphens only. BEM `__element` / `--modifier` separators are **rejected** — use
  `.card-title` / `.card-title-active`, not `.card__title` / `.card--active`.
- **stylelint `comment-empty-line-before`** — a comment needs a blank line before it (unless it's the
  first thing in its block or directly follows an opening brace).
- **stylelint `no-descending-specificity`** — a lower-specificity selector must not override a
  higher-specificity one that appears earlier; order rules so specificity is non-descending (or scope
  them so they don't collide).
- **markdownlint `MD040`** — every fenced code block needs a language tag (```` ```sh ````,
  ```` ```json ````, etc.); a bare ```` ``` ```` fence fails.
- **markdownlint `MD013`** — lines must be **≤ 400 characters**;
  `config/lint/markdownlint-fast.json` sets `line_length: 400` to mirror CI (Super-Linter's bundled
  markdownlint uses the same 400 limit — see the "Markdown line-length" caveat below); wrap long prose
  and split wide table rows.

Caveats:

- **Apple Silicon:** Super-Linter ships no arm64 image, so `make lint` runs it under emulation
  (`--platform linux/amd64`) — correct, but slower than native. Under that emulation the
  `GITHUB_ACTIONS` validator (actionlint) crashes with a SIGSEGV, so `make lint` **skips it on
  arm64** (and says so); check workflows with **`make lint-actions`**, which runs actionlint natively
  (pinned to the version Super-Linter bundles). On amd64 (CI/Intel) nothing is skipped. `make
  lint-fast` stays the quick inner-loop check.
- **Markdown line-length:** `make lint-fast`'s markdownlint config
  (`config/lint/markdownlint-fast.json`) mirrors Super-Linter's **MD013 `line_length: 400`** (and its
  default table/code-block behaviour), so an over-length line — e.g. a wide table row that can't wrap
  — now fails `lint-fast` as it does in CI. Native `markdownlint-cli2` and Super-Linter's bundled
  markdownlint can still differ on newer/edge rules; `make lint` remains the exact mirror.
- **Scope:** locally, Super-Linter lints the whole workspace; in CI it lints only files changed
  against `main`. Local is broader, not narrower.
- **Vercel:** the deploy-preview check runs on Vercel's side and is **not** covered by `make lint`;
  it can only be validated after pushing.

### Visual + PDF gate

`.github/workflows/visual.yml` (name: `Visual`, job `Visual + PDF checks`) is a **required PR check**
that guards how the site renders. It runs in the **pinned Playwright image**
(`mcr.microsoft.com/playwright:v1.61.1-noble`) — the same image `make visual` uses locally — so CI
rendering matches the committed baselines exactly (cross-environment font rendering is the #1 snapshot
flake).

- **Triggers:** `push` to `main` and every `pull_request`.
- **What it does:** `npm ci` → `npm run build` (the noble image ships no `make`) → `npx playwright
  test`, running three specs, then uploads the Playwright HTML report + diff images as an artifact on
  failure:
  - `tests/visual.spec.js` — `toHaveScreenshot({ fullPage: true })` of `dist/index.html` at the six
    Bootstrap breakpoints (375/576/768/992/1200/1440), diffed against `tests/__screenshots__/`.
  - `tests/pdf.spec.js` — asserts the build produced a valid, non-empty `dist/*.pdf` (`%PDF-` header).
  - `tests/pdf-visual.spec.js` — **PDF visual-regression:** rasterises every page of the built PDF
    to a PNG (via [`mupdf`](https://www.npmjs.com/package/mupdf), a pure-WASM engine — no native
    binaries or apt packages) and `toMatchSnapshot`s each against a committed baseline
    (`tests/__screenshots__/pdf-visual.spec.js/pdf-page-NN.png`), so a change to the PDF's
    content/layout fails the gate (`pdf.spec.js` only checks the PDF *exists* and is valid). It also
    asserts the baseline count matches the rendered page count, catching a page added or removed.
- **Determinism:** baselines are committed and rendered in the pinned image; snapshots run with
  `reducedMotion: 'reduce'` and a test-only `tests/snapshot.css` that forces scroll-reveal elements to
  their settled state and hides the daily "Last update" date, so re-runs are stable. The PDF-visual
  spec adds two determinism levers: `mupdf` is byte-deterministic (so it uses an *exact* pixel match,
  `maxDiffPixels: 0`, rather than the screen gate's 0.01 ratio — a one-line text edit changes only
  ~0.1 % of a page and would slip past a loose ratio), and the build's "Last update" date is pinned
  via `SOURCE_DATE_EPOCH` (set by the `make visual` / `make visual-update` targets and matched in
  `visual.yml`) so the date baked into the PDF is stable day-to-day; the value is chosen so the screen
  render stays identical to the committed screen baselines.

Run it locally (same result as CI):

```sh
make visual         # build + run the gate in the pinned Playwright image
make visual-update  # regenerate the committed baselines after an *intentional* visual change
```

`make visual` is the authoritative check; `make visual-update` is a **reviewed** step — when a change
deliberately alters the page **or the PDF**, run it and commit the regenerated PNGs (screen
breakpoints *and* PDF pages) in the same PR (the baseline diff is the review surface). A missing or
mismatched baseline fails the gate (CI never passes `--update-snapshots`). Baselines are generated
only in the pinned image via `make visual-update` — never on the host toolchain, whose fonts differ.

### Dev Container image prebuild

`.github/workflows/devcontainer.yml` (name: `Dev Container`) prebuilds the Dev Container image and
publishes it to the GitHub Container Registry (GHCR), so `devcontainer up` — on any machine and in
each `make worktree` — pulls cached layers instead of building the image from scratch.

- **Triggers:** runs on **every** pull request (so it can be a required check — see below) and on
  `push` to `main` filtered to the paths that determine the image (`.devcontainer/**`,
  `package.json`, `package-lock.json`, and the workflow file); plus manual `workflow_dispatch`. On a
  PR it first detects whether those inputs changed and **skips the build (reporting success) when
  they didn't**, so unrelated PRs stay fast and unblocked.
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
- **Required check (no deadlock):** because the job runs and reports on every PR — building when the
  inputs changed, skipping *green* when they didn't — `Build, smoke-test, and publish` is a
  **required** status check on `main`, alongside `Lint`, `Visual + PDF checks`, and `Build and
  deploy`. A path-filtered check *can't* be required: on PRs that don't touch its paths it never
  runs, so a required context waits "Expected" forever and blocks the merge. Dropping the
  trigger-level `paths` filter from `pull_request` (and skipping the build in-job instead) is what
  makes it safe to require.

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
