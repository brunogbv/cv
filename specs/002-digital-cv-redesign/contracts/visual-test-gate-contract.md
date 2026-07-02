# Contract: visual-regression + PDF-render test gate

The automated quality gate (FR-007/FR-008, SC-002). It is the safety net built first; the redesign is
verified against it.

## What it checks

| Check | Definition | Pass condition |
|-------|-----------|----------------|
| Responsive rendering | Playwright `toHaveScreenshot({ fullPage: true })` of `dist/index.html` at each Bootstrap breakpoint (375/576/768/992/1200/1440) | Each screenshot matches its committed baseline within tolerance (`maxDiffPixelRatio: 0.01`, `threshold: 0.2`) |
| PDF render | The build's `dist/*.pdf` | File exists, size > ~1 KB, and starts with the `%PDF-` header |

**Out of scope for this gate**: keyboard navigation and colour-contrast (FR-011) are *not* checked by
the visual/PDF gate — they are verified by manual review during the redesign. Automated accessibility
assertions (e.g. axe-core) would add a dependency and are deferred as possible future work; the
reduced-motion aspect of FR-011 *is* covered (via `reducedMotion: 'reduce'` in the capture).

## How it runs

- **Locally**: `make visual` — builds (`make page`) then runs the Playwright suite **inside the Dev
  Container** (Linux), so results match CI. `make lint` / `make lint-fast` remain separate.
- **CI**: `.github/workflows/visual.yml` on `ubuntu-latest` — `npm ci` → cache + `playwright install
  --with-deps chromium` → `make page` → `npx playwright test`. **Required PR check.** On failure it
  uploads the Playwright HTML report + diff images as an artifact.
- **Loading**: the page is loaded as `file://…/dist/index.html` (same as `pdf.js`) — no server.

## Determinism (required, or the gate is flaky)

- Baselines are generated/compared **only in the Linux Dev Container / CI**; host (macOS) baselines
  are never committed. A platform-neutral `snapshotPathTemplate` prevents a stray host run from
  creating a divergent baseline.
- `animations: 'disabled'` (default) + `reducedMotion: 'reduce'` + a test-only `stylePath`
  (`tests/snapshot.css`, forcing `.reveal` visible) make the captured state deterministic despite the
  IntersectionObserver reveal.
- Vendored fonts (no CDN) + `document.fonts.ready` remove font/network nondeterminism.

## Baseline update flow

- Intentional visual changes are applied via **`make visual-update`** (wraps `playwright test
  --update-snapshots` in the Dev Container). The regenerated PNGs are committed and **reviewed in the
  PR** (GitHub's image diff). This is the *only* way baselines change.

## Failure semantics

- A responsive regression (overflow, hidden section), an **unintended** visual diff, or a PDF-render
  failure → the check **fails and blocks the PR** before anything is published (SC-002).
- CI never passes `--update-snapshots`, so a **missing baseline fails** (it does not silently create
  one).
