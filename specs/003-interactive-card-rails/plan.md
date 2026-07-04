# Implementation Plan: Digital CV — interactive editorial deck

**Branch**: `003-respec` | **Date**: 2026-07-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-interactive-card-rails/spec.md` (re-spec)

## Summary

Rebuild the digital (screen) CV as an **editorial, full-viewport vertical "deck"**: each section fills
the viewport with vertically-centred content, and one gesture/keypress advances exactly one section,
resting centred. Scrolling is **native CSS Scroll Snap** (`scroll-snap-type: y mandatory` +
`scroll-snap-stop: always`) — the browser owns wheel/trackpad/touch momentum; a **thin JS layer** adds
one-section-per-keypress via `scrollIntoView` (coexists with snap; no wheel/touch interception). The
three content-dense sections become **horizontal summary-card rails** (native `x` scroll-snap + peek);
activating a card opens the full entry in a **full-screen detail overlay** (CSS `:target` baseline,
dialog a11y layered on as progressive enhancement). The screen adopts an **editorial restyle**
(Fraunces display + Spline Sans body, both **vendored** screen-only; cream/ink/slate/terracotta; no
boxy cards; skills as proficiency chips). The distinctive **signature** is **"The Through-Line"** — a
fixed terracotta thread down the left margin with one node per section that fills as you snap, doubling
as the progress/section-nav spine. Everything is **screen-only**; `@media print` flattens back to the
existing clean, linear **Roboto PDF** (unchanged). `pdf.js` gains one line — `emulateMedia('print')`
before navigating — to guarantee screen-only CSS/webfonts never reach the PDF. The existing visual + PDF gate
guards it — screen baselines regenerated (intentional restyle), the PDF baseline unchanged as the
guardrail.

## Technical Context

**Language/Version**: Node 22 build (Handlebars templating); vanilla browser **JavaScript (ES2020+)**
for the progressive-enhancement layer; CSS (native scroll-snap + `:target`).

**Primary Dependencies**: existing — Handlebars, Playwright, Bootstrap 5, vendored Roboto + Font
Awesome. **New (dev only, vendored like Roboto)**: `@fontsource-variable/fraunces` +
`@fontsource-variable/spline-sans` (OFL-1.1), copied into `dist/vendor/` by the existing `build.js`
loop. **No runtime dependency, no framework, no CDN.**

**Storage**: N/A — static site; CV content stays in `src/metadata/metadata.js` (unchanged).

**Testing**: the existing Playwright **visual-regression + PDF-visual gate** (`make visual` /
`make visual-update`, `tests/`); screen baselines regenerated (intentional), PDF baseline unchanged.

**Target Platform**: static site on Vercel; modern evergreen browsers, graceful degradation for no-JS
and for engines lacking `inert` (feature-detected → `aria-hidden` fallback).

**Project Type**: single static web project (no backend/frontend split).

**Performance Goals**: main content visible < ~2.5s on mobile (SC-009); scrolling is native (browser
compositor, 60fps); **no layout shift** from the deck, rails, overlay, fonts, or signature (CLS ≈ 0);
fonts vendored → no third-party request at render time (SC-008).

**Constraints**: PDF unchanged (SC-005); the **page never scrolls horizontally** — only rails scroll
in their own track (SC-003); the deck **rests on a section, never between** (SC-001); accessible
(keyboard, SR region/list/dialog, visible focus, focus trap+return on the overlay, reduced-motion)
(SC-006); **all content reachable with no JS** (SC-004); deterministic snapshots; vanilla / no
framework (FR-016); native scroll-snap, **no JS scroll-jacker** (D1 / gotchas doc).

**Scale/Scope**: ~6 deck panels; 3 become summary-card rails (~4–11 cards each) with a detail overlay
per entry; 1 signature (Through-Line); 2 vendored fonts; ~2 small JS assets (deck keyboard + overlay
a11y, or one combined) + CSS + template edits + regenerated screen baselines. Content unchanged.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.* Checked against
constitution **v1.3.0**.

- **I. The Makefile is the interface** — ✅ Reuses `make page(-container)` / `make visual` /
  `make visual-update` / `make lint`. New vendored fonts are picked up by the existing `build.js`
  `vendoredAssets` copy loop; the PE JS is copied by the existing `src/assets` → `dist/` step (like
  `reveal.js`). No new target.
- **II. Self-review before done** — ✅ Each increment runs `/code-review` and is recorded before PR.
- **III. Docs stay in sync** — ✅ `architecture.md` (deck/rail/overlay + vendored fonts + screen/print),
  `interaction-gotchas.md` (already corrected), and an **ADR 0004** for the chosen approach (native
  snap deck) land with the work.
- **IV. Validate locally; CI gates are the safety net** — ✅ Both gates apply; screen baselines are
  regenerated (intentional restyle, reviewed via `make visual-update`); the **PDF baseline stays
  unchanged** as the screen-only guardrail. No constitution amendment needed.
- **V. Reproducible and minimal** — ✅ Vanilla; the only new deps are two OFL variable fonts vendored
  exactly like Roboto (no CDN, no framework). Snapshot determinism reuses the pinned Playwright image.
- **VI. The harness is a living system** — ✅ The scroll-jacking→native-snap learning was already
  codified (`docs/interaction-gotchas.md`, #175); further gaps surfaced rather than patched ad hoc.

**Result: PASS — no violations.** Complexity Tracking below is intentionally empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-interactive-card-rails/
├── plan.md              # This file
├── research.md          # Phase 0 — technical + design decisions (D1–D10)
├── data-model.md        # Phase 1 — presentation model (deck panels / rails / cards / overlays / chips)
├── quickstart.md        # Phase 1 — validation scenarios
├── contracts/
│   └── interaction-contract.md   # Phase 1 — deck/rail/overlay DOM+ARIA, screen/print, PE, gate
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

(The stale rails-era `design.md` is removed; its design system + signature are folded into
`research.md` D6/D8.)

### Source Code (repository root)

```text
package.json                 # Add @fontsource-variable/{fraunces,spline-sans} devDeps
src/
├── build.js                 # Extend vendoredAssets: copy the two fonts' axis CSS + latin woff2
├── templates/index.html     # Deck panels (full-viewport sections); summary-card rails on the 3 dense
│                            #   sections; :target detail overlays (role=dialog, target="_self" anchors,
│                            #   visible close); the Through-Line nav/progress; link vendored font CSS;
│                            #   reference the PE scripts (screen-only effects)
├── assets/
│   ├── styles.css           # Editorial restyle (screen-only fonts/palette/eyebrows/chips); deck
│   │                        #   (100vh panels + scroll-snap); rails (x snap + peek + overscroll-behavior);
│   │                        #   :target overlay + scroll-lock; Through-Line; @media print flattens ALL
│   │                        #   of it to the existing linear Roboto PDF
│   ├── deck.js              # NEW — PE: keyboard one-section-per-key (scrollIntoView), Through-Line
│   │                        #   fill/aria-current (reuses a section IntersectionObserver)
│   ├── overlay.js           # NEW — PE: detail-overlay dialog a11y (focus move/trap/return, inert, Esc)
│   └── reveal.js            # Existing — opacity-only reveal (kept; no transform, per prototype)
└── metadata/metadata.js     # UNCHANGED (content)

tests/
├── visual.spec.js           # Deterministic resting state (scroll top, fonts ready, overlay closed)
├── pdf.spec.js              # PDF visual check stays green + unchanged (the guardrail)
├── snapshot.css             # Extend for determinism if needed (e.g. normalize scrollbars)
└── __screenshots__/         # Screen baselines regenerated (reviewed); PDF baseline unchanged
```

**Structure Decision**: Single static project, unchanged shape. The feature is additive CSS + small
vanilla JS assets + template edits + two vendored fonts, on top of the 002 foundation — no new
directories or build steps; fonts reuse the `build.js` vendored-asset loop, JS reuses the `reveal.js`
copy precedent. (Deck + overlay JS MAY be one file; kept separate here for clarity — a tasks-level call.)

## Complexity Tracking

> No constitution violations — nothing to justify.
