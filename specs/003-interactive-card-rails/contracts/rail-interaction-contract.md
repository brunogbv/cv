# Contract: card-rail interaction (screen vs. print)

What a card rail MUST satisfy. Extends the 002 rendering contract (screen/print CSS decoupling); the
rail layer is screen-only and flattens in print. Verified by the visual + PDF gate and by manual
keyboard/screen-reader/no-JS checks.

## Structure & semantics

| Aspect | Requirement |
|--------|-------------|
| Container | Each rail is a **labelled, focusable, scrollable region**: `role="region"` (or `group`) + an accessible name (`aria-label`/`aria-labelledby`) + `tabindex="0"` on the scroll container (portable keyboard access — Safari/older engines don't focus scrollers natively). (D1, D2) |
| List | Cards are a plain `<ul>`/`<li>` inside the container → SR announces an ordered, counted list. **No** `aria-roledescription`, tablist, or play/pause. (D1) |
| Cards | One `<li>` per entry; the entry's real links/buttons remain the focus targets. Cards are **not** given `tabindex` unless the whole card is the interactive unit. Off-screen cards stay in the DOM and tab order. (D2) |

## Screen (`@media screen`)

| Aspect | Requirement |
|--------|-------------|
| Behavior | Horizontal **scroll-snap**: one focal card + a **peek** of the next, snapping between cards, at **every** breakpoint (no multi-card grid). `scroll-snap-type: x mandatory`; cards `scroll-snap-align: start` with a sub-100% basis + `min-width: 0`; `scroll-padding-inline` for the peek gutter. (D4, FR-001) |
| Page overflow | The **page never scrolls horizontally** — only the rail's own track. `overscroll-behavior-x: contain` prevents scroll-chaining/ swipe-nav at the rail ends. (FR-003, SC-002, D4) |
| Input | Operable by **touch (swipe), pointer, and keyboard**; a non-touch way to advance is available (arrow-scroll the focused region, and/or prev/next controls). (FR-002) |
| Focus | Visible focus on the region and on card contents; `scroll-padding` + gutter + `outline-offset` keep focus rings from being clipped by the track (WCAG 2.4.7 / 2.4.11). (D2) |
| Affordance | It is obvious the rail is swipeable and how much more exists: the **peek** + the **route-indicator** signature (position + count). A hidden scrollbar MUST be replaced by such an affordance. (FR-002, D4) |
| Signature | A screen-only **"route between nodes"** position indicator: one node per card, active node in the `signal` accent; also the `aria-live` position target. (design.md, FR-008) |
| Motion | Snapping always on; the animated smooth-scroll glide + node pulse gated behind `prefers-reduced-motion: no-preference`; JS scrolls branch on `matchMedia('(prefers-reduced-motion: reduce)')`. No layout shift. (D5, FR-009) |

## Progressive enhancement (no JS)

| Aspect | Requirement |
|--------|-------------|
| Baseline | With **no JavaScript**, each rail is a horizontally scrollable, snapping strip with **all cards present and reachable** (swipe / trackpad / keyboard). Nothing is hidden or requires a script to reveal. (FR-006, SC-003) |
| JS layer | `src/assets/rails.js` is **additive only** — prev/next controls, the route indicator's interactivity, and an `aria-live` position status. It MUST NOT gate access to any card, and MUST fail visible (any error leaves content reachable). (D3) |

## Print / PDF (`@media print`, via `page.pdf()`)

| Aspect | Requirement |
|--------|-------------|
| Form | Rails **flatten** to the existing clean, linear entries — the container is not a scroller, cards stack linearly, `break-inside: avoid` per entry (as 002). |
| Chrome | The route indicator, prev/next controls, scroll track, and all rail motion are **absent** in the PDF. |
| Cross-link | Download-PDF (screen) and QR (print) intact. |
| Generation | Produced by the **unchanged** `src/utils/pdf.js` (default print media, A4). **No `emulateMedia`**; the **PDF is byte-for-content unchanged** from 002 (same entries, order, layout). (FR-005, SC-004) |

## Gate (visual-regression + PDF-render)

| Aspect | Requirement |
|--------|-------------|
| Coverage | The rails' **deterministic resting state** is captured in the committed breakpoint baselines; the PDF-render check stays green. |
| Determinism | Before asserting: `history.scrollRestoration = 'manual'`, reset each rail's `scrollLeft = 0`, disable smooth scroll, `await document.fonts.ready`, normalize the scrollbar; keep Playwright `animations:'disabled'`; allow a small `maxDiffPixelRatio` for subpixel snap jitter. Baselines generated in the pinned Playwright image, never the host. (D6) |
| Review | Intentional visual changes update the committed baselines as a reviewed step (`make visual-update`); an unintended diff fails the gate. |

## Invariants (carried from 002)

- One template, one stylesheet; no separate print template; no `pdf.js` change; vendored fonts (no CDN).
- Static-only (no backend/DB/API); the existing template engine retained (no framework). (FR-011)
- Local dev, the build pipeline, and the Vercel deploy flow continue to work unchanged. (FR-012)
