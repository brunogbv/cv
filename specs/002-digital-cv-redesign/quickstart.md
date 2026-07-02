# Quickstart: validating the digital CV redesign

Runnable checks that prove the feature works. All build/test steps run in the **Dev Container** (or
CI), not the host (constitution IV / V). See [contracts/](contracts/) for the full rules.

## Prerequisites

- Dev Container up (`make dev` / VS Code "Reopen in Container").
- `@playwright/test@1.61.1` installed (`npm ci`), Chromium present (`npx playwright install chromium`).

## Scenario 1 — The gate passes on a good build (US1)

**One-time baseline generation** (before the gate can pass — capture the current page as the golden
reference, run in the Dev Container / Linux so baselines match CI):

```sh
make visual-update    # generates the baseline PNGs from the current page; commit them
```

Then validate that a no-op change passes:

```sh
make visual
```

Expected: `make page` builds `dist/` (HTML + PDF); the Playwright suite screenshots the page at all 6
Bootstrap breakpoints and matches the committed baselines, and the PDF check passes. Exit 0.

(During the P2/P3 redesign, intentional visual changes fail this check until `make visual-update` is
re-run and the new baselines are committed + reviewed — see research.md "Baseline cadence".)

## Scenario 2 — The gate catches a responsive regression (US1 / SC-002)

Introduce a deliberate break (e.g. a fixed-width element wider than the mobile viewport), then:

```sh
make visual
```

Expected: the 375/576 snapshots fail with a pixel diff over tolerance; the job exits non-zero and (in
CI) uploads diff images. Revert → `make visual` passes again.

## Scenario 3 — The gate catches a broken PDF (US1)

Force a PDF-render failure (e.g. break `src/utils/pdf.js` temporarily). Expected: `make visual` fails
at the PDF check (missing / empty / no `%PDF-` header) **before** any deploy. Revert to restore.

## Scenario 4 — Navigable, card-based screen; simple PDF (US2)

Open `dist/index.html` in a browser at phone, tablet, and desktop widths. Expected: content in
sections + cards, a sticky section nav (collapsing to a menu on mobile), no horizontal scrolling, a
working **Download PDF** button. Open `dist/<slug>.pdf`: a clean linear document — **no** nav/cards
chrome, content and order unchanged from before, **QR** present.

## Scenario 5 — Motion is tasteful and accessible (US3)

- Default: sections gently reveal on scroll; no layout jump.
- OS "reduce motion" on: content appears immediately, no animation, fully usable.
- JS disabled: all content is visible (nothing stuck hidden).

## Scenario 6 — Intentional visual change (baseline update)

Make a deliberate design change, then:

```sh
make visual-update   # regenerates baselines in the Dev Container
```

Expected: baseline PNGs update; commit them; the PR shows the before/after image diff for review.
Without this step, the intended change would (correctly) fail `make visual`.

## Success check

- `make visual` green locally and as a **required PR check** in CI.
- `make lint` still green; `npm start` / `make page` / `make dev-build` still work (no regression).
- The PDF is unchanged in content + linear form; both cross-links resolve.
