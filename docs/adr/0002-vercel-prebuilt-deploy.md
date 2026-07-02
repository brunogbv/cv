# 0002 — Build in CI and deploy prebuilt to Vercel

- **Status:** Accepted — implemented across PRs #93 (US1) + #95 (US2 runbook) + this PR (US3/Polish);
  issues #24, #44–#63
- **Date:** 2026-07-02

## Context

The site was hosted on a manually-operated GCP VM (nginx + certbot, orchestrated by
`docker-compose.yml` and ~15 Makefile targets), with DNS pointing at the VM's IP. Deploys and cert
renewal were manual, and the site had gone down. Vercel was already linked to the repo, but every
native Vercel build **failed** and there was no `vercel.json`.

Forces:

- The build renders a **PDF at build time via headless Chromium (Playwright)**, pinned by the
  lockfile. Vercel's native build environment is not a place we control that browser/version — the
  main reason native builds failed.
- The build pulled fonts/CSS from **remote CDNs** and waited on `networkidle` (issue #24) — a
  reproducibility gap that also breaks in a sandboxed build.
- Both a correct **HTML page and a matching PDF** must remain available.
- TLS should be automatic (retire manual certbot); deploys should be reproducible and not depend on
  third-party CDN availability at build time.

## Decision

**Build in GitHub Actions and deploy the prebuilt output to Vercel via the Vercel CLI**
(`vercel deploy --prebuilt`), rather than letting Vercel build natively.

- CI (`.github/workflows/deploy.yml`) runs Node 22 + the lockfile-pinned Playwright Chromium, then
  `make page` to produce `dist/` (HTML + PDF), then `make deploy` (`vercel pull` → `vercel build` →
  `vercel deploy --prebuilt`). Push to `main` → production (aliased to `valerio.dev`); PR → preview.
- `vercel.json` sets `framework: null` + `buildCommand: ""` so `vercel build` **packages the existing
  `dist/`** instead of re-running the Node build (which would relaunch Chromium in Vercel's env).
  Vercel's own git build is disabled (`git.deploymentEnabled: false`) so the workflow is the sole
  deploy path.
- **Vendored fonts/CSS (#24):** Bootstrap, Font Awesome, and Roboto are copied from pinned
  `node_modules` into `dist/vendor/` at build time, and `pdf.js` waits on `load` +
  `document.fonts.ready` (no `networkidle`). The build no longer depends on any CDN.
- **Apex-canonical:** `valerio.dev` is the primary domain; `www.valerio.dev` 301-redirects to it.
  TLS is provisioned and renewed automatically by Vercel.
- The manual VM stack (`docker-compose.yml`, `config/nginx/`, the `webserver*` / `certificates*` / …
  Makefile targets) is **retired**.

## Alternatives considered

- **Native Vercel build** (let Vercel run `npm run build`). Rejected: it re-runs the Chromium/PDF
  render in Vercel's build sandbox — exactly what was failing, and not pinnable the way the lockfile
  Playwright is. Building in our own CI keeps the browser pinned and reproducible.
- **Keep the GCP VM** (nginx + certbot). Rejected: manual deploys and cert renewal, a single host to
  maintain, and the site had already gone down. Vercel gives push-to-deploy, previews, and automated
  TLS with no server to run.
- **GitHub Pages.** Rejected: no per-PR preview deployments and awkward for the prebuilt-artifact
  flow; the repo's old `gh-pages` `predeploy` script was already dead.

## Consequences

- **Positive:** every push deploys; per-PR previews with a posted URL; automated TLS; reproducible
  offline builds (no CDN dependency); no server or certbot to operate; the deploy command lives in
  the `Makefile` (`make deploy`), consistent with the "Makefile is the interface" principle.
- **Negative / trade-offs:** deploys depend on the Vercel CLI + a `VERCEL_TOKEN` secret and on the
  Vercel platform; the Vercel CLI is installed unpinned in CI (`npm i -g vercel`) — a minor
  reproducibility gap, acceptable because the deploy is of an already-built artifact.
- **Follow-ups:** Vercel Deployment Protection auth-walls previews by default, so production must be
  kept public (captured in the cutover runbook in `docs/ci-cd.md`). Pinning the Vercel CLI version
  would close the remaining reproducibility gap.
