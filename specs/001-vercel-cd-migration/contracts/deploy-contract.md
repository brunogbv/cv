# Contract: CI → Vercel deploy interface

The GitHub Actions workflow (`.github/workflows/deploy.yml`) is the sole deploy path. Vercel's own
git build is disabled.

## Triggers → environment

| Trigger | Environment | Vercel CLI |
|---------|-------------|------------|
| `push` to `main` | production | `vercel pull --environment=production` → `vercel build --prod` → `vercel deploy --prebuilt --prod` |
| `pull_request` | preview | `vercel pull --environment=preview` → `vercel build` → `vercel deploy --prebuilt` |

## Steps (both environments)

1. `actions/checkout`
2. `actions/setup-node` (Node 22) + `npm ci`
3. Restore/save cache of `~/.cache/ms-playwright` keyed on the resolved Playwright version **and**
   the runner OS (browser binaries only)
4. `npx playwright install --with-deps chromium` — the pinned Chromium (parity-critical). Note
   `--with-deps` reinstalls apt system libraries every run (not covered by the step-3 cache)
5. `make page` — build `dist/` incl. the PDF
6. `make deploy` (with `--prod` on `main`) — see below
7. Capture the deploy URL from `make deploy` / CLI stdout and post it to the PR

## `make deploy` (Principle I — the deploy command lives in the Makefile)

`make deploy` encapsulates the Vercel CLI sequence so CI does not call `vercel` ad hoc:
`vercel pull` → `vercel build` → `vercel deploy --prebuilt`, reading `VERCEL_TOKEN`/`VERCEL_ORG_ID`/
`VERCEL_PROJECT_ID` from the environment. Production vs preview is selected by a variable
(e.g. `make deploy PROD=1` adds `--prod` and `--environment=production`). Because `vercel.json` sets
`framework: null` + `buildCommand: ""`, the `vercel build` inside `make deploy` **packages the
already-built `dist/`** rather than re-running `node src/build.js`.

## Inputs

- Secrets: `VERCEL_TOKEN`; env: `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

## Outputs / observable behavior

- **Preview** (PR): a unique preview URL, posted back to the PR as a comment / job summary (the
  Vercel bot does **not** auto-comment in a CLI-only setup — the workflow must surface it). Satisfies
  FR-002.
- **Production** (`main`): the deployment is aliased to `valerio.dev`. Satisfies FR-001.

## Failure semantics

- If `make page` fails (incl. PDF render error) the job fails **before** any deploy → nothing is
  published; the last good production deployment keeps serving (FR-008).
- The build MUST NOT depend on external CDN availability (FR-003) — fonts/CSS are vendored, so step
  5 succeeds with no external network to font/CSS CDNs (verified in quickstart).
