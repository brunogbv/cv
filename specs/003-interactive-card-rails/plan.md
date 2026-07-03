# Implementation Plan: Digital CV — interactive swipeable card rails

**Branch**: `003-interactive-card-rails` | **Date**: 2026-07-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/003-interactive-card-rails/spec.md`

## Summary

Turn the three content-dense sections (Professional Experience, Additional Experience, Robotics
Competitions) into **horizontally swipeable card rails** on the screen, layered on the 002
card/section page. Each rail shows one focal card with a peek of the next and snaps between cards. The
implementation is **CSS-first** — native `scroll-snap` provides the swipe/peek/snap with **no
JavaScript required** — wrapped in a **labelled, focusable, scrollable `region`** for accessibility;
a small progressive-enhancement script adds affordances (prev/next, a position indicator) but never
gates content. The whole rail layer is **screen-only** and flattens in `@media print` to the existing
linear entries, so the **PDF is unchanged**. The distinctive **signature** is a "route between nodes"
position indicator (the rail's cards as ordered nodes on a route, the active card the live node) —
tying the interaction to the subject's distributed-systems / dispatch-routing domain. The existing
visual + PDF gate guards it, with new deterministic baselines for the rails' resting state.

## Technical Context

**Language/Version**: Node 22 build (Handlebars templating); vanilla browser **JavaScript (ES2020+)**
for the light progressive-enhancement layer; CSS (native scroll-snap).

**Primary Dependencies**: existing only — Handlebars, Playwright (`playwright` + `@playwright/test`),
Bootstrap 5, vendored Roboto + Font Awesome. **No new runtime dependency, no framework, no new font.**

**Storage**: N/A — static site; CV content stays in `src/metadata/metadata.js` (unchanged).

**Testing**: the existing Playwright **visual-regression + PDF-render gate** (`make visual` /
`make visual-update`, `tests/`), extended with the rails' deterministic resting state.

**Target Platform**: static site on Vercel; modern evergreen browsers, with graceful degradation for
no-JS and for engines that don't make scroll containers keyboard-focusable natively (Safari,
pre-132 Chromium) — handled with `tabindex="0"` + `role`/label on the container.

**Project Type**: single static web project (no backend/frontend split).

**Performance Goals**: main content visible < ~2.5s on mobile (SC-008); swipe uses native scroll
(smooth 60fps); **no layout shift** from the rails or signature (CLS ≈ 0).

**Constraints**: PDF unchanged (SC-004); the **page never scrolls horizontally** — only rails scroll
in their own track (SC-002); accessible (keyboard-operable, SR-exposed list, visible focus, WCAG 2.2
focus-not-obscured, reduced-motion) (SC-005); **all content reachable with no JS** (SC-003);
deterministic snapshots; vanilla / no framework (FR-011).

**Scale/Scope**: 3 sections become rails (~4–11 cards each); 1 signature element; ~1 small JS file +
CSS + template changes + baseline updates. Content unchanged.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.* Checked against
constitution **v1.3.0**.

- **I. The Makefile is the interface** — ✅ Reuses `make page` / `make visual` / `make visual-update`
  / `make lint`. No new workflow needed (the light JS asset is copied by the existing `src/assets`
  copy, like `reveal.js`); no new target required.
- **II. Self-review before done** — ✅ Each increment runs `/code-review` and is recorded before PR.
- **III. Docs stay in sync** — ✅ Docs (architecture.md, the rendering contract, ci-cd if the gate
  changes) updated in the same PRs / a polish pass; a follow-up ADR if the rail approach is a notable,
  durable decision.
- **IV. Validate locally; CI gates are the safety net** — ✅ Both gates apply; the visual + PDF gate is
  **extended** to cover the rails' resting state. **No constitution amendment needed** (v1.3.0 already
  recognizes the two gates — unlike 002, which had to amend Principle IV).
- **V. Reproducible and minimal** — ✅ Vanilla, **no new dependency, no new vendored font**; the rail
  is native CSS + a tiny JS enhancement. Snapshot determinism reuses the pinned Playwright image.
- **VI. The harness is a living system** — ✅ Will surface any gap (e.g. gate mechanics for
  scroll-state) rather than patch ad hoc.

**Result: PASS — no violations.** Complexity Tracking below is intentionally empty.

## Project Structure

### Documentation (this feature)

```text
specs/003-interactive-card-rails/
├── plan.md              # This file
├── research.md          # Phase 0 — technical + design decisions
├── design.md            # Phase 0 — frontend-design token system + signature + wireframes
├── data-model.md        # Phase 1 — presentation model (rails/cards/route indicator)
├── quickstart.md        # Phase 1 — validation scenarios
├── contracts/
│   └── rail-interaction-contract.md   # Phase 1 — rail behavior, a11y, PE, print, gate
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
src/
├── templates/index.html     # Add rail markup (region + <ul> of cards) to the 3 dense sections;
│                            #   reference the rails enhancement script (screen-only effect)
├── assets/
│   ├── styles.css           # Rail layout (scroll-snap + peek), a11y focus/scroll-padding, the
│   │                        #   route-indicator signature; @media print flattens rails to linear
│   └── rails.js             # NEW — progressive-enhancement: prev/next, position indicator,
│                            #   reduced-motion-aware scrolling (additive; content works without it)
└── metadata/metadata.js     # UNCHANGED (content)

tests/
├── visual.spec.js           # Extend: rails' deterministic resting state (reset scroll, fonts)
├── snapshot.css             # Extend if needed for determinism (e.g. normalize scrollbar)
└── __screenshots__/         # Regenerated baselines (reviewed) for the rail resting state
```

**Structure Decision**: Single static project, unchanged. The feature is additive CSS + one small
vanilla JS asset + template edits, on top of the 002 layout — no new directories, dependencies, or
build steps. `rails.js` follows the `reveal.js` precedent (screen-only progressive enhancement, copied
verbatim by the existing `src/assets` → `dist/` step).

## Complexity Tracking

> No constitution violations — nothing to justify.
