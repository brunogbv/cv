# Contract: deck / rail / overlay interaction (screen vs. print)

What the interactive editorial deck MUST satisfy. Extends the 002 rendering contract (screen/print CSS
decoupling); the whole interaction + restyle layer is **screen-only** and flattens in print to the
existing linear Roboto PDF. Verified by the visual + PDF gate and by manual keyboard / screen-reader /
no-JS / reduced-motion checks.

## A. Deck (full-viewport vertical sections)

| Aspect | Requirement |
|--------|-------------|
| Structure | Each section (`header`, `.cv-section`) is a full-viewport panel: `min-height: 100vh`, content vertically centred; `scroll-snap-align: start; scroll-snap-stop: always`. `html { scroll-snap-type: y mandatory }`. (D1, FR-001) |
| Native scroll | Wheel / trackpad / touch are **100% browser-driven** (native snap). **No JS scroll-jacker** — JS MUST NOT intercept `wheel`/`touch` to animate scrolling. (D1, gotchas doc, FR-002) |
| Rest state | After any gesture the deck **rests on a section, never between two**; a hard flick advances **one** section (`scroll-snap-stop: always`). (SC-001) |
| Keyboard | A thin JS layer moves one section per Arrow/Page press via `scrollIntoView({behavior})` (coexists with snap); ignores auto-repeat and when focus is in a field/overlay. (D1, FR-002) |
| Breakpoints | Applies at **all** breakpoints; a panel whose content **exceeds the viewport** relaxes to internal scroll (mandatory snap only for panels that fit). (D2, FR-001) |
| Reduced motion | Snapping **kept** (rest position); smooth glide + transitions **suppressed** under `prefers-reduced-motion`. (D2, FR-014) |

## B. Summary-card rails (3 content-dense sections)

| Aspect | Requirement |
|--------|-------------|
| Semantics | Each rail is a labelled list: a `<ul>`/`<li>` (SR announces an ordered, counted list). No APG carousel/tablist/roledescription. (D3) |
| Behaviour | Horizontal **scroll-snap**: one focal summary card + a **peek** of the next, at every breakpoint (no multi-card grid). `scroll-snap-type: x mandatory`; cards `scroll-snap-align: start` with sub-100% basis + `min-width: 0`; `scroll-padding-inline` for the peek gutter. (D3, FR-003) |
| Nested scroll | The rail sets `overscroll-behavior: contain` + `touch-action: pan-x pan-y` so an X-fling does not chain to / trigger the vertical deck snap, and vice versa. The flex/scroll item is the `<li>`, not the inner `<a>`. (D4, FR-006) |
| Page overflow | The **page never scrolls horizontally** — only the rail's own track. (FR-006, SC-003) |
| Summary card | Short: period, title, teaser. It is the activator: `<a href="#pN" target="_self">`. |
| Focus | Visible focus on cards; `scroll-padding` + gutter + `outline-offset` keep focus rings from being clipped. |

## C. Detail overlay (per entry)

| Aspect | Requirement |
|--------|-------------|
| Baseline (no JS) | CSS `:target`: `#pN` overlay shown when the card's `href="#pN"` targets it; close via anchors to `#experience` (backdrop + a **visible** close control); `body:has(.proto-detail:target){overflow:hidden}` locks background scroll. Full content reachable + dismissible with **no JS**. (D5, FR-005) |
| Presentation | Full-screen: a focused card (full `contents` + skill badges) on a dimmed/blurred backdrop; one open at a time; opening/closing does not scroll the section off-centre; background does not scroll while open. (FR-004) |
| Dialog a11y (PE) | When JS runs: static `role="dialog" aria-modal="true" aria-labelledby`; on `hashchange` move focus **into** the overlay, **trap** Tab within it, **return** focus to the triggering card on close; mark background `inert` (feature-detected; fallback `aria-hidden`); **Escape** closes (routes through `location.hash='experience'`). Never breaks the no-JS baseline. (D5, FR-012) |
| Anchors | Every overlay anchor (card, backdrop, visible close) MUST set `target="_self"` (defeats `<base target="_blank">`). (D5, gotchas doc) |

## D. Editorial restyle + signature (screen-only)

| Aspect | Requirement |
|--------|-------------|
| Type | Headings Fraunces (variable, `font-optical-sizing: auto`); body Spline Sans; both **vendored** (no CDN), referenced **only** in `@media not print`. (D6, D7, FR-007/8) |
| Palette / layout | cream/ink/slate/terracotta tokens; no boxy cards; uppercase terracotta eyebrows (`data-eyebrow`); skills as proficiency-fill chips. Screen-only. (D6) |
| Signature | The **Through-Line**: fixed terracotta thread in the left gutter, one node per section, fills on snap; `.screen`-classed; `position: fixed` (CLS ≈ 0); doubles as progress/section-nav; reduced-motion → jump not tween; no-JS → static jump-link index. (D8) |

## E. Progressive enhancement (no JS)

| Aspect | Requirement |
|--------|-------------|
| Baseline | With **no JavaScript**: the deck still snaps (pure CSS), rails are scrollable snapping strips, overlays open/close via `:target`, the Through-Line is a static index of jump links. **100%** of content reachable; nothing hidden behind a script. (D10, FR-011, SC-004) |
| JS layer | `deck.js` / `overlay.js` are **additive only**, gated by `.js` on `<html>` (set before first paint, the `reveal.js` precedent). They enrich (keyboard nav, focus mgmt, Through-Line fill) and MUST fail visible. (D10) |

## F. Print / PDF (`@media print`, via `page.pdf()`)

| Aspect | Requirement |
|--------|-------------|
| Form | Deck panels, rails, overlays, chips, restyle, and the Through-Line **flatten/vanish**; entries render as the existing clean, linear **Roboto** blocks, `break-inside: avoid` per entry (as 002). |
| Fonts | Print keeps **Roboto** — the screen font families are referenced only under `@media not print`, and the vendored editorial fonts are linked `media="screen"` so they are never fetched for the PDF. |
| Generation | Produced by `src/utils/pdf.js` (A4), which now calls `page.emulateMedia({ media: 'print' })` **before** navigating so screen-only CSS/webfonts never affect the PDF — it renders exactly the print document. **PDF unchanged** from 002 (same entries, order, typography, layout); machine-verified by the PDF-visual baseline. (FR-009, SC-005) |
| Cross-link | Download-PDF (screen) and QR (print) intact. |

## G. Gate (visual-regression + PDF-visual)

| Aspect | Requirement |
|--------|-------------|
| Coverage | The **deterministic resting state** (deck on the hero, no overlay open) is captured in the committed screen breakpoint baselines; the **PDF visual check** (#164) stays green. |
| Determinism | Before asserting: `history.scrollRestoration='manual'`, scroll to top, ensure no `:target` overlay, disable smooth scroll, `await document.fonts.ready`, normalize scrollbars; Playwright `animations:'disabled'`; small `maxDiffPixelRatio` for subpixel snap jitter. Baselines built in the pinned Playwright image, never the host. (D9) |
| Screen vs PDF | **Screen** baselines are regenerated (intentional restyle → `make visual-update`, reviewed). The **PDF** baseline MUST stay **unchanged** — it is the machine-checked proof the restyle/deck is screen-only. (D9, SC-005) |

## Invariants (carried from 002)

- One template, one stylesheet; no separate print template; no `pdf.js` change; vendored fonts (no CDN).
- Static-only (no backend/DB/API); existing template engine retained (no framework). (FR-016)
- Local dev, the build pipeline, and the Vercel deploy flow continue to work unchanged. (FR-017)
