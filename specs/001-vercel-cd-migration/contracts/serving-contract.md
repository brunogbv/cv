# Contract: HTTP serving surface

What the production domain exposes once cut over to Vercel. Verifiable with `curl -sI`.

## Routes

| Request | Response |
|---------|----------|
| `GET /` | `200`, `text/html` — the CV page |
| `GET /<slug>.pdf` | `200`, `application/pdf` — the CV PDF (existing filename preserved, FR-005) |
| `GET /assets/*` | `200`, correct content-type — static assets |
| `GET /index.html` | `308` → `/` (cleanUrls) |
| `GET /<path>/` | `308` → `/<path>` (trailingSlash=false) |
| `GET /<unknown>` | `404` (Vercel default not-found) |

## Host + scheme redirects

| From | To | Code |
|------|-----|------|
| `http://valerio.dev/*` | `https://valerio.dev/*` | `308` (Vercel automatic HTTPS) |
| `https://www.valerio.dev/*` | `https://valerio.dev/*` | `301` (Vercel domain redirect) |

## Headers (`Cache-Control` + security)

| Path glob | Configured `Cache-Control` (in `vercel.json`) |
|-----------|-----------------|
| `/` (HTML) | `public, max-age=0, s-maxage=86400, stale-while-revalidate=86400` |
| `*.pdf` | `public, max-age=0, s-maxage=86400, stale-while-revalidate=86400` |
| `*.{css,js,png,jpg,jpeg,svg,webp,ico,woff,woff2}` | `public, max-age=0, s-maxage=31536000, stale-while-revalidate=86400` |
| `/(.*)` | `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin` |

> **Client vs edge**: when only `Cache-Control` is set, Vercel **strips `s-maxage` and
> `stale-while-revalidate` before responding to the client** — they govern the edge/CDN only. So
> `curl -sI` observes `public, max-age=0, must-revalidate` for HTML/PDF/assets, while the edge still
> caches per `s-maxage`. Verify the *client* value (`max-age=0`) with curl; edge caching is an
> internal behavior. (If an asset's edge TTL ever needs to be client-visible, use
> `CDN-Cache-Control`, which Vercel forwards.)

Freshness invariant (FR-012): a new deployment invalidates the edge cache, and the client-facing
`max-age=0` forces browser revalidation — so an updated page/PDF is visible promptly; unhashed
assets are edge-cached but browser-revalidated (no `immutable`, since asset filenames are
stable/unhashed).

## TLS

Valid, auto-renewing certificate for `valerio.dev` and `www.valerio.dev` (FR-006). No manual
issuance/renewal.

## Reference `vercel.json`

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": null,
  "buildCommand": "",
  "outputDirectory": "dist",
  "cleanUrls": true,
  "trailingSlash": false,
  "git": { "deploymentEnabled": false },
  "headers": [
    { "source": "/", "headers": [
      { "key": "Cache-Control", "value": "public, max-age=0, s-maxage=86400, stale-while-revalidate=86400" } ] },
    { "source": "/(.*)\\.pdf", "headers": [
      { "key": "Cache-Control", "value": "public, max-age=0, s-maxage=86400, stale-while-revalidate=86400" } ] },
    { "source": "/(.*)\\.(css|js|png|jpg|jpeg|svg|webp|ico|woff|woff2)", "headers": [
      { "key": "Cache-Control", "value": "public, max-age=0, s-maxage=31536000, stale-while-revalidate=86400" } ] },
    { "source": "/(.*)", "headers": [
      { "key": "X-Content-Type-Options", "value": "nosniff" },
      { "key": "X-Frame-Options", "value": "DENY" },
      { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" } ] }
  ]
}
```

`framework: null` + `buildCommand: ""` are required so `vercel build` in CI **packages the
already-built `dist/`** (produced by `make page`) instead of auto-detecting the `build` npm script
and re-running `node src/build.js` (which would launch Chromium again). The apex↔www redirect is
configured in Vercel Domain settings, **not** here (path-based `redirects` cannot match by host).

**Out of scope (accepted defaults)**: unknown paths serve Vercel's generic 404 (no custom `404.html`
is planned); no `robots.txt`/`sitemap.xml` is added. Call these out later if the public CV wants a
branded 404 — no spec requirement covers them.
