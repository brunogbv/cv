# Quickstart: validating the interactive editorial deck

Runnable checks that prove the feature works end-to-end. Build in the Dev Container / pinned image (not
the host), per the repo convention. See [spec.md](spec.md),
[contracts/interaction-contract.md](contracts/interaction-contract.md).

## Prerequisites

- The 003 worktree, Docker (for `make visual` / the pinned image).
- Build: `make page-container` (or `npm run build` in the pinned image) → `dist/index.html` + `dist/*.pdf`.

## Scenario 1 — Deck: one section per gesture, rests centred (US1, SC-001)

1. Open `dist/index.html` on a desktop viewport. Scroll with the mouse wheel, then a **hard trackpad
   flick**, then Arrow/Page keys.
2. **Expect**: each gesture/press advances **exactly one section**; the page **rests centred on a
   section, never between two**; a hard flick advances only one. The sticky/section nav (Through-Line)
   jumps to a section and rests centred too.

## Scenario 2 — Deck on mobile + tall panels (US1, D2)

1. Resize across xs/sm/md/lg/xl/xxl (and a real phone if possible).
2. **Expect**: the deck holds at all breakpoints; any section taller than the viewport scrolls
   internally rather than clipping; the page **never scrolls horizontally**.

## Scenario 3 — Rails + detail overlay (US2, SC-002)

1. On Professional Experience (and Additional / Competitions), swipe/scroll the **rail** of summary
   cards; tap/click a card, then close it (visible close, click outside, and — with JS — Esc).
2. **Expect**: one focal summary card + a peek; swiping the rail does **not** move the deck; a card
   opens its **full** detail full-screen on a dimmed/blurred backdrop; closing returns to the section
   **centred**; the background never scrolled while open.

## Scenario 4 — Screen reader + keyboard (US4, SC-006)

1. Keyboard-only: traverse the deck, tab through a rail's cards, open a card, Tab within the overlay,
   close it. With a screen reader, enter a rail and open an entry.
2. **Expect**: sections announced as labelled regions, rails as labelled lists of cards, the open detail
   as a **dialog**; focus moves **into** the overlay, is **trapped**, and **returns** to the card on
   close; visible focus throughout.

## Scenario 5 — No JavaScript (US4, SC-004)

1. Disable JavaScript; reload `dist/index.html`.
2. **Expect**: the deck still snaps (CSS), rails are still scrollable strips, each detail overlay still
   opens/closes via the `#pN` / `#experience` links, the Through-Line is a static index of jump links.
   **100%** of content reachable; nothing hidden.

## Scenario 6 — Reduced motion (US4, FR-014)

1. Enable "reduce motion" at the OS level; navigate the deck and open an overlay.
2. **Expect**: sections still **snap to rest** (instant, no smooth glide); overlay/emphasis transitions
   and the Through-Line fill **jump** rather than animate; everything stays functional.

## Scenario 7 — Editorial restyle + vendored fonts (US3, SC-008)

1. On screen, confirm Fraunces headings + Spline Sans body, the cream/terracotta palette, eyebrow
   labels, and skills-as-chips. In DevTools Network, reload and filter fonts.
2. **Expect**: fonts load from `vendor/...` (same-origin) — **no third-party/CDN request**; no visible
   layout shift on font swap.

## Scenario 8 — PDF unchanged (US1/US2/US3, SC-005)

1. Open `dist/<name>.<title>.pdf` (and diff against a pre-003 build / the committed PDF baseline).
2. **Expect**: same sections and entries in the same **linear** order, **Roboto** typography; **no**
   deck/rail/overlay/chip/Through-Line chrome; `break-inside: avoid` per entry; QR + "Online at"
   present. Unchanged from 002.

## Scenario 9 — Signature: the Through-Line (US5)

1. Watch the left-margin terracotta thread as you snap through sections.
2. **Expect**: one node per section; the fill/active node advances one hop per snap; on-brand and
   disciplined; reduced-motion → jump not tween; absent in the PDF; no layout shift.

## Scenario 10 — The gate catches regressions (SC-007)

1. `make visual` → all screen breakpoints + the **PDF visual** check pass against committed baselines.
2. Introduce a deliberate regression (e.g. a rail overflows the page horizontally, or a screen font
   leaks into print so the PDF baseline moves) → `make visual` fails with the diff.
3. Revert → green. For the *intentional* restyle, `make visual-update` regenerates the **screen**
   baselines (reviewed; commit PNGs) — the **PDF** baseline must stay unchanged.

## Success-criteria map

| Scenario | Criteria |
|----------|----------|
| 1 | SC-001 |
| 2, 3 | SC-002, SC-003 |
| 4 | SC-006 |
| 5 | SC-004 |
| 6 | FR-014 |
| 7 | SC-008, SC-009 |
| 8 | SC-005 |
| 9 | SC-009 (no layout shift) |
| 10 | SC-007 |
