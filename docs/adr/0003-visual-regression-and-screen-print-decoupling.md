# 0003 — Visual-regression gate + screen/print decoupling for the CV redesign

- **Status:** Accepted — implemented across the `002-digital-cv-redesign` milestone (US1 #126,
  US2 #132, US3 #133, Polish); issues #100–#122
- **Date:** 2026-07-03

## Context

The digital CV was deliberately kept visually plain because the **same** Handlebars markup generates
both the on-screen page and the PDF (via Playwright `page.pdf()`), so any screen richness risked
complicating the PDF. We wanted a richer, responsive, card/section-based screen experience with a
sticky nav and subtle motion — without regressing the clean, linear PDF, and without a way for such a
redesign (or any future change) to silently break rendering on some device or break the PDF.

Forces:

- **No test suite existed** — linting was the only automated gate (old constitution Principle IV), so
  a CSS/layout regression could ship unnoticed. A redesign this visual needed a safety net *first*.
- Rendering checks must be **deterministic** — cross-environment font rendering is the top cause of
  screenshot flakiness, and the build already vendors fonts (no CDN, #24).
- The PDF must stay a **clean linear document**; `src/utils/pdf.js` renders default print media and
  should not need to change.
- Any client-side motion must be **accessible** (reduced-motion, keyboard) and must not hide content
  if JavaScript fails — the site is a static, no-backend build.

## Decision

**1. A visual-regression + PDF-render gate, built tests-first (US1).** `@playwright/test`
`toHaveScreenshot({ fullPage: true })` snapshots `dist/index.html` at the six Bootstrap breakpoints
(375/576/768/992/1200/1440) against committed baselines in `tests/__screenshots__/`; a second spec
asserts the build produced a valid PDF. It is a **required PR check** (`.github/workflows/visual.yml`)
and runs locally via `make visual` / `make visual-update`.

- **Determinism:** the gate runs in a **pinned Playwright image**
  (`mcr.microsoft.com/playwright:v1.61.1-noble`) — the same image locally and in CI — plus the
  vendored fonts, `maxDiffPixelRatio` tolerance, `reducedMotion: 'reduce'`, and a test-only
  `tests/snapshot.css` that forces scroll-reveal elements to their settled state and hides the daily
  "Last update" date. Baselines are committed and updated as a **reviewed** step (`make visual-update`).

**2. Screen/print decoupling driven by CSS media (US2).** One template + one stylesheet; the rich
screen presentation (cards, sticky section nav) is confined to `@media (not print)`, and `@media print`
flattens the cards, hides the nav, and reproduces the pre-redesign linear layout. `pdf.js` is
unchanged (no `emulateMedia`). Skills keep their original grid markup (un-carded) because a Bootstrap
`.row`'s gutters render differently inside a card box in print — keeping that structure identical
guarantees the PDF's skills grid is byte-identical.

**3. Accessible, fail-visible scroll-reveal (US3).** `src/assets/reveal.js` sets a `.js` root class
(before first paint), then a one-shot `IntersectionObserver` reveals `.reveal` sections. Content is
**visible by default**; only with `.js` set *and* `prefers-reduced-motion: no-preference` does it start
hidden and ease in (opacity/transform only — no layout shift). It **fails visible**: no JS, no
`IntersectionObserver`, or any setup error reveals everything; `@media print` forces it visible.

## Alternatives considered

- **No test gate (rely on manual PDF checks + lint).** Rejected: a visual redesign with no regression
  net is exactly how a broken breakpoint or PDF ships unnoticed; the gate also delivered value against
  the *current* page before any redesign landed.
- **DOM diffing / a headless assertion library instead of pixel snapshots.** Rejected: the risk is
  *visual* (overflow, layout, fonts), which pixel snapshots capture directly; DOM assertions miss it.
- **A separate print template (or `emulateMedia` in `pdf.js`).** Rejected: two templates drift and the
  build stays simpler with one source; a CSS media split keeps content parity by construction and
  leaves `pdf.js` untouched.
- **A CSS-only reveal (e.g. scroll-driven animations) or a heavier animation library.** Rejected:
  scroll-driven CSS lacks the reduced-motion/no-JS safety and broad support we wanted; a library is
  unnecessary weight for a subtle one-shot reveal.
- **Cross-OS/browser snapshot matrix.** Rejected: a single pinned Linux image (matching CI) is
  deterministic and cheap; a matrix multiplies flakiness and baselines for little value on a static
  page.

## Consequences

- **Positive:** every PR is gated on how the page renders at all breakpoints *and* on the PDF still
  building; intentional visual changes are explicit, reviewed baseline diffs. The screen can now evolve
  boldly while the PDF stays safe — the decoupling is the platform for future screen-only interactivity.
  The animation is accessible and degrades gracefully.
- **Negative / trade-offs:** baselines are binary PNGs in git (they change whenever the design does —
  a reviewed cost); the gate depends on the pinned Playwright image (bump deliberately); `break-inside:
  avoid` on entries can leave whitespace when a long entry bumps to the next page (accepted — entries
  are never split). This amends **constitution Principle IV** (v1.2.0 → 1.3.0): CI now has two gates
  (lint + visual), not one.
- **Follow-ups:** consider extending the gate's determinism notes if content grows; a bolder
  gesture/deck screen experience is scoped as its own future initiative (the decoupling makes it safe).

**Update (#157):** the PDF is now **pixel-gated**, not validity-only. `tests/pdf-visual.spec.js`
rasterises every PDF page with `mupdf` (pure WASM — no native/apt deps) and diffs each against a
committed baseline (exact match, since the render is byte-deterministic); the "Last update" date is
pinned via `SOURCE_DATE_EPOCH` so the PDF is stable day-to-day. A change to the PDF's content/layout
now fails a PR, and intentional PDF changes update baselines via `make visual-update` (as the screen
snapshots do). This strengthens decision **1** without changing it (the original `pdf.spec.js`
validity check stays).
