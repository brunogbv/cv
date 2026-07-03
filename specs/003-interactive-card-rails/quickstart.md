# Quickstart: validating interactive card rails

Runnable checks that prove the feature works end-to-end. Build in the Dev Container / pinned image (not
the host), per the repo convention. See [spec.md](spec.md), [contracts/](contracts/rail-interaction-contract.md).

## Prerequisites

- The 003 worktree (`../cv-003-interactive-card-rails`), Docker (for `make visual` / the pinned image).
- Build: `make page-container` (or `npm run build` in the pinned image) → `dist/index.html` + `dist/*.pdf`.

## Scenario 1 — Rails render and swipe (US1)

1. Open `dist/index.html`; resize across xs/sm/md/lg/xl/xxl.
2. **Expect**: Professional Experience, Additional Experience, and Robotics Competitions each render as
   a horizontal rail — one focal card + a peek of the next — that snaps between cards on swipe/drag.
   Header, About, Skills unchanged. The **page never scrolls horizontally** at any width.

## Scenario 2 — Desktop / pointer + keyboard (US1, US2)

1. On a desktop viewport, Tab to a rail; use arrow keys (and any prev/next control) to move through
   cards; Tab into a card's links.
2. **Expect**: the rail region is focusable with a visible focus ring; cards advance; the focused
   card/links are never clipped by the track; a position/route indicator shows where you are and that
   more cards exist.

## Scenario 3 — Screen reader (US2)

1. With a screen reader, navigate into a rail.
2. **Expect**: it's announced as a labelled region containing a list of N cards; you can move through
   them in order; position changes are announced (`aria-live`). No "carousel/slide/tab" mislabeling.

## Scenario 4 — No JavaScript (US2, SC-003)

1. Disable JavaScript; reload `dist/index.html`.
2. **Expect**: every rail is still a horizontally scrollable strip; **all** cards/entries are reachable
   (swipe/trackpad/keyboard) and readable; nothing is hidden; the page still works.

## Scenario 5 — Reduced motion (US2)

1. Enable "reduce motion" at the OS level; interact with a rail and the nav.
2. **Expect**: snapping still works (instant, no glide); no node pulse or non-essential animation; the
   rail stays fully functional.

## Scenario 6 — PDF unchanged (US1, SC-004)

1. Open `dist/<name>.<title>.pdf` (and diff against a pre-003 build).
2. **Expect**: same sections and entries in the same **linear** order; **no** rail chrome, route
   indicator, or controls; `break-inside: avoid` per entry; QR + "Online at" present. Byte-for-content
   unchanged from 002.

## Scenario 7 — The gate catches regressions (US1, SC-006)

1. Run `make visual` → all breakpoints + the PDF check pass against the committed baselines.
2. Introduce a deliberate regression (e.g. remove `min-width: 0` so a rail overflows the page, or break
   the PDF) → `make visual` fails and reports the diff/failure.
3. Revert → green. For an *intentional* rail visual change, `make visual-update` regenerates the
   baselines (reviewed; commit the PNGs).

## Scenario 8 — Signature & polish (US3)

1. On screen, observe the "route between nodes" indicator under each rail as you move through cards.
2. **Expect**: one distinctive, on-brand signature; active node in the signal accent; reduced-motion
   respected; absent in the PDF; no layout shift.

## Success-criteria map

| Scenario | Criteria |
|----------|----------|
| 1, 2 | SC-001, SC-002 |
| 3, 5 | SC-005 |
| 4 | SC-003 |
| 6 | SC-004 |
| 7 | SC-006, SC-007 |
| 8 | SC-008 (no layout shift) |
