# Quickstart: validate the Vercel migration

End-to-end validation scenarios that prove the feature works. Each maps to spec user stories and
success criteria. Run in order; later phases depend on earlier ones. (Implementation details live in
`tasks.md`; this is a run/verify guide.)

## Prerequisites

- Node 22 + repo deps (`npm ci`) and the pinned Playwright Chromium
  (`npx playwright install --with-deps chromium`), or the Dev Container.
- A Vercel account with the `cv` project; `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` set
  as GitHub Actions secrets.
- Owner access to the `valerio.dev` DNS (for Phase B only).

## Scenario 1 — Reproducible, self-contained build (US1 / SC-003, FR-003)

```sh
make page                      # builds dist/ incl. the PDF
```

Expected: `dist/index.html` + `dist/<slug>.pdf` produced; open both and confirm correct fonts
(Roboto) and Font Awesome icons render. Then prove no CDN dependency — build with external network
blocked (e.g. disable networking / offline) and confirm the build still succeeds and the PDF fonts
are unchanged (no fallback fonts, no hang). `grep -r "https://" dist/index.html` returns **no**
font/CSS CDN links.

## Scenario 2 — Preview deployment per PR (US1 / FR-002, SC-002)

Open a PR. Expected: the `deploy` workflow builds and posts a **preview URL** comment on the PR.
Open the URL → the CV page and the PDF render correctly over HTTPS. A build failure fails the job
and posts no preview (FR-008).

## Scenario 3 — Production deployment from main (US1 / FR-001, SC-001, SC-006)

Merge to `main`. Expected: the workflow runs `--prod`; the deployment is aliased to the production
domain. No manual server or certificate step is involved (SC-006). Verify the serving contract:

```sh
curl -sI https://<production-deployment-url>/            # 200, text/html; client Cache-Control: public, max-age=0
curl -sI https://<production-deployment-url>/<slug>.pdf  # 200, application/pdf
# note: s-maxage / stale-while-revalidate are edge-only and stripped from the client response
```

## Scenario 4 — Domain cutover (US2 / FR-006, FR-007, FR-009, SC-004, SC-005)

Owner steps (runbook): add `valerio.dev` + `www.valerio.dev` to the Vercel project; set `www` to
**Redirect to** the apex; lower DNS TTL; **verify Vercel serving + a valid certificate first**, then
point DNS (`A → 76.76.21.21`, `www CNAME → <project>.vercel-dns-###.com`). Verify:

```sh
dig A valerio.dev +short                       # matches the A record shown in Vercel Domain settings
curl -sI https://valerio.dev/                  # 200, valid TLS
curl -sI https://www.valerio.dev/              # 301 → https://valerio.dev/
```

Because the site is currently down and the VM is already off, this **restores** availability — there
is no rollback target and no downtime to protect (per Clarifications).

## Scenario 5 — VM stack retired (US3 / FR-010)

After production is verified on Vercel:

```sh
grep -rn "webserver\|certbot\|nginx" Makefile   # no deploy targets remain
ls docker-compose.yml config/nginx 2>/dev/null  # removed
```

Expected: the manual deploy stack + its Makefile targets are gone; `docs/ci-cd.md` / `README` /
`AGENTS.md` describe the push-to-deploy model with no manual server/cert instructions.

## Success check

All five scenarios pass → SC-001…SC-007 satisfied and the migration is complete.
