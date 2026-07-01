# Phase 1 Data Model: Migrate hosting & CD to Vercel

This feature is infrastructure, not application data — the "entities" are configuration and
deployment objects. Captured here so tasks and contracts have a shared vocabulary.

## Build output (`dist/`)

The artifact produced by `make page` (`node src/build.js`) and uploaded to Vercel.

| Field | Description | Validation |
|-------|-------------|------------|
| `index.html` | Rendered CV page | MUST exist; references only **local** assets (no CDN URLs) |
| `<slug>.pdf` | Rendered PDF (`<name>.<title>.pdf` via `speakingurl`) | MUST exist, be non-empty, embed the vendored fonts (no fallback fonts) |
| `assets/` | Copied `src/assets/` incl. `assets/vendor/` (fonts + CSS) | Vendored Roboto, Bootstrap 5.2.0, Font Awesome 6.1.2 present |
| `assets/*` (favicons, `photo.jpg`, `styles.css`, QR) | Existing assets | Unchanged |

Invariant: a deployment is only valid if **both** `index.html` and the PDF are present and
correctly fonted (FR-004). The build MUST fail loudly if PDF rendering fails (no partial output).

## Deployment

A single build published to Vercel.

| Field | Values |
|-------|--------|
| `environment` | `production` (from `main`) \| `preview` (from a PR) |
| `sourceRef` | git SHA / branch |
| `url` | Vercel deployment URL (preview: unique `*.vercel.app`; production: aliased to `valerio.dev`) |
| `state` | `queued` → `building`(in CI) → `uploading` → `ready` \| `error` |

State rules: a build/PDF failure ends in `error` and is **not** promoted; the last `ready`
production deployment keeps serving (FR-008). Production `--prod` aliases the deployment to the
canonical domain.

## Domain

| Host | Role | DNS record (owner-run) | Redirect |
|------|------|------------------------|----------|
| `valerio.dev` | **canonical** | `A → <IP from Vercel dashboard>` (`76.76.21.21` legacy default) | — (serves) |
| `www.valerio.dev` | redirect | `CNAME → <project>.vercel-dns-###.com` | `301 → https://valerio.dev` |

TLS: Vercel auto-provisions and renews Let's Encrypt certificates for both hosts once DNS verifies
(replaces certbot). Records are exact-valued from the Vercel dashboard.

## Vercel project configuration (`vercel.json` + dashboard)

| Setting | Value | Where |
|---------|-------|-------|
| `outputDirectory` | `dist` | `vercel.json` |
| `framework` / `buildCommand` | `null` / `""` — so `vercel build` packages the prebuilt `dist/` instead of re-running `node src/build.js` | `vercel.json` |
| `git.deploymentEnabled` | `false` | `vercel.json` |
| `cleanUrls` / `trailingSlash` | `true` / `false` | `vercel.json` |
| `Cache-Control` + security headers | per content type | `vercel.json` `headers` (see serving-contract) |
| Git repo connection | disconnected | dashboard |
| Primary domain + www redirect | apex primary; www→apex | dashboard Domain settings |

## CI secrets (GitHub Actions)

| Secret | Purpose |
|--------|---------|
| `VERCEL_TOKEN` | Auth for the Vercel CLI |
| `VERCEL_ORG_ID` | Target org (from `.vercel/project.json`) |
| `VERCEL_PROJECT_ID` | Target project (from `.vercel/project.json`) |
