# Phase 0 Research: Migrate hosting & CD to Vercel

Resolves the open technical questions the spec deferred to planning. Grounded in current
(2025–2026) Vercel + Playwright documentation.

## 1. How is the PDF produced in a Vercel world? (the central fork)

**Decision**: Build the **whole site (HTML + PDF) in GitHub Actions** using the repo's
lockfile-pinned Playwright Chromium, then deploy the prebuilt `dist/` to Vercel via the Vercel CLI
(`vercel build` → `vercel deploy --prebuilt`). Vercel never launches a browser.

**Rationale**:
- Playwright's bundled Chromium does **not** launch reliably in Vercel's native build image
  (Amazon Linux); the canonical failure is missing shared libraries (`libnspr4.so`, etc.), and you
  cannot install system deps there the way `playwright install-deps` expects on Debian. This is
  almost certainly why the current (no-`vercel.json`) Vercel builds fail — Vercel auto-detects and
  runs `node src/build.js`, which calls `chromium.launch()`.
- GitHub Actions `ubuntu-latest` is the same Debian/Ubuntu family the repo's `node:22-bookworm`
  Docker/devcontainer already use, where `playwright install --with-deps chromium` works. Rendering
  the PDF there uses the **exact pinned Chromium** — so the PDF is byte-faithful to local builds
  (satisfies SC-007 parity and FR-003/Principle V reproducibility) with **zero** env-specific launch
  branching and **no** new runtime dependency.
- A static CV's PDF is a build artifact, not per-request compute — there's no reason to put Chromium
  in Vercel's build or runtime.

**Alternatives considered**:
- **Native Vercel build via `@sparticuz/chromium` + `playwright-core`** — rejected: introduces a
  *second* Chromium binary (decoupled from the lockfile), env-specific launch code, and a package
  designed for the AWS Lambda *runtime*, not a build step. Breaks parity + reproducibility; more
  moving parts. Fails every stated priority.
- **Runtime PDF via a Vercel Serverless Function** — rejected: over-engineered; turns a build
  artifact into per-request compute with cold-start/size-limit concerns, still non-pinned Chromium.
- **Fixing system libs for stock Playwright in Vercel's build** — rejected: cannot reliably install
  the missing `.so` deps in Vercel's build image; a losing battle.

## 2. Disabling Vercel's own build; deploying prebuilt from CI

**Decision**: Commit `"git": { "deploymentEnabled": false }` in `vercel.json` **and** keep the
Vercel project's GitHub repo disconnected (belt-and-suspenders). Deploy only via
`vercel deploy --prebuilt` from GitHub Actions.

**Rationale**: `git.deploymentEnabled: false` is the first-class, repo-committed switch that turns
off Vercel's automatic git builds for all branches (the deprecated `github.enabled` is superseded);
CLI deploys are unaffected because they hit the project directly via token, not the git webhook.
A project with no connected repo simply has nothing to auto-build, which most robustly kills the
current failing builds. `vercel deploy --prebuilt` uploads the previously generated `.vercel/output`
and **skips the build on Vercel**.

**Alternatives**: "Ignored Build Step" (`git.ignoreCommand`)/dashboard toggles — still fire the git
integration and create skipped-deployment noise; the right tool for conditional monorepo skips, not
for "never build on Vercel." Dashboard-only toggles aren't versioned.

**CI flow** (`.github/workflows/deploy.yml`): checkout → setup Node 22 → `npm ci` →
`npx playwright install --with-deps chromium` (cache `~/.cache/ms-playwright` keyed on the resolved
Playwright version **and** runner OS — note `--with-deps` reinstalls apt system libraries each run,
so the deps step is not fully cached) → `make page` (build incl. PDF) → `npm i -g vercel` →
`make deploy` (wraps `vercel pull` → `vercel build` → `vercel deploy --prebuilt`, `--prod` selected
via a flag). `--prod` on push to `main` (aliases to `valerio.dev`); plain deploy on PRs (preview
URL). Secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

**Critical config**: `vercel.json` sets `framework: null` + `buildCommand: ""` so `vercel build`
**packages the already-built `dist/`** instead of auto-detecting the `build` npm script and
re-running `node src/build.js` (which would launch Chromium a second time). Without this override
the "Vercel never launches a browser" property does not hold.

## 3. `vercel.json` for a prebuilt static site + caching

**Decision**: `outputDirectory: "dist"`, `cleanUrls: true`, `trailingSlash: false`, and explicit
per-type `Cache-Control`, plus baseline security headers.

**Rationale**: Vercel's default (`max-age=0, must-revalidate`) caches nothing. `s-maxage` and
`stale-while-revalidate` control Vercel's edge only and are **stripped before the response reaches
the client** (so `curl -sI` shows `public, max-age=0, must-revalidate` — verify the client value,
not the edge directives), while `max-age` controls the browser, and a new deployment invalidates the
edge cache — so `max-age=0, s-maxage=…, stale-while-revalidate=…` gives "browser always gets the
freshest HTML/PDF after a deploy, edge still serves fast, **no stale-cache lock-in**" (satisfies
FR-012). The repo's assets have **stable, unhashed filenames**, so
`immutable` would strand old CSS after a redesign → assets use `max-age=0, s-maxage=31536000,
stale-while-revalidate` (switch to `max-age=31536000, immutable` only if content-hashing is added).

**Concrete config** captured in [`contracts/serving-contract.md`](contracts/serving-contract.md).

## 4. Apex vs www + DNS

**Decision**: `valerio.dev` (apex) canonical; `www.valerio.dev` → **301** → apex. Do the redirect
via Vercel **Domain settings** (add both domains, mark apex primary, set www "Redirect to" apex),
**not** a `vercel.json` `redirects` rule.

**Rationale**: `vercel.json` `redirects` match by path, not host, so they're the wrong tool for
apex↔www; the domain-level redirect is a proper host-wide 301 at the edge. DNS records (owner-run at
the registrar, using the **exact values shown in the project's Domain settings**): apex `A → <IP
from dashboard>` (`76.76.21.21` is the legacy default and still valid, but read the dashboard value);
`www` `CNAME → <project>.vercel-dns-###.com`. Vercel auto-provisions Let's Encrypt TLS once DNS
verifies.

**Caveat**: Vercel's own recommendation is the *opposite* (www primary via CNAME) because a CNAME
lets their CDN steer traffic; apex-primary hard-codes an Anycast IP. Apex-primary is fully
supported and chosen for the cleaner canonical URL — an accepted, minor tradeoff for a personal CV.

## 5. Preview/production visibility on PRs

**Decision**: Capture the deploy URL from the Vercel CLI `stdout` and post it to the PR ourselves
(`actions/github-script` or `gh pr comment`) / job summary.

**Rationale**: Disabling the Vercel git integration means the **Vercel bot no longer auto-comments**
preview URLs or sets commit statuses. The CLI always prints the deployment URL to stdout, so the
workflow surfaces it. Prefer the minimal `github-script`/`gh` comment over a third-party action
(Principle V: minimal trust surface), unless the GitHub "Deployments" tab integration is wanted.

## 6. Issue #24 — self-contained build (prerequisite for P1)

**Decision**: Vendor the three CDN dependencies into `src/assets/vendor/` and reference them
locally; render with `waitUntil: 'load'` and `await page.evaluate(() => document.fonts.ready)` before
`page.pdf()` so the vendored fonts are actually applied; add an explicit `page.goto` timeout as
defense-in-depth; and fix `build.js` so the PDF is awaited and failures are fatal — wrap the build
body in a CommonJS-safe `(async () => { … })().catch(err => { console.error(err); process.exit(1) })`
(a bare top-level `await` is a SyntaxError in this CommonJS module).

Note: once assets are local (`file://`), `networkidle` resolves immediately, so it is no longer a
hang risk — but a `goto` timeout alone does **not** catch a *missing* local font (the page still
"loads" with fallback fonts). `document.fonts.ready` + the quickstart's visual check are what
guarantee font correctness (SC-003/FR-004).

**Rationale**: The template loads Roboto (Google Fonts), Bootstrap 5.2.0 (jsDelivr), and Font
Awesome 6.1.2 (cdnjs) from CDNs, and `pdf.js` waits on `networkidle` — so a slow/unreachable CDN can
hang the build or silently produce a fallback-font PDF. Vendoring makes the CI-rendered PDF
deterministic regardless of network (FR-003, SC-003) and is a hard prerequisite for reliable Vercel
builds. Font Awesome and Roboto ship self-host bundles; Bootstrap CSS is a single vendored file.

**Alternatives**: keep CDNs + rely on CI network — rejected (nondeterministic, the exact #24
problem). Replace the browser-based PDF with a non-Chromium renderer — rejected (parity risk).
