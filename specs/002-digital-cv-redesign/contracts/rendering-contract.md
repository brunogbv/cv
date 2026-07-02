# Contract: rendering surface (screen vs. print)

What the two outputs of the single build MUST satisfy. Both come from one Handlebars template + one
CSS file; the divergence is CSS-media-driven (`@media screen` vs `@media print`). Verified by the
visual-test gate (see [visual-test-gate-contract.md](visual-test-gate-contract.md)) and by inspecting
the generated PDF.

## Screen (digital page) — `@media screen`

| Aspect | Requirement |
|--------|-------------|
| Layout | Content in **sections** with **card**-based items; scannable, not a flat wall of text (FR-001). |
| Navigation | A **sticky section navigation** with anchor links to each section; collapses to a `<details>` menu on mobile; smooth-scroll gated by reduced-motion; `scroll-margin-top` offsets the sticky bar (FR-002). |
| Responsiveness | Renders correctly at **all Bootstrap breakpoints** (375/576/768/992/1200/1440): no horizontal overflow, every section visible/legible, controls reachable (FR-004, SC-001). |
| Animation | **Subtle** scroll-reveal (transform/opacity only); honors `prefers-reduced-motion`; no layout shift (FR-003, SC-005). |
| Fallback | With **no JS** (or before the observer fires), all content is fully visible — never left `opacity:0` (edge case: progressive enhancement). |
| Cross-link | A working **"Download PDF"** control is present (FR-006). |
| Accessibility | Keyboard-navigable; reduced-motion respected; sufficient contrast (FR-011). |

## Print / PDF — `@media print` (via `page.pdf()`, default print media)

| Aspect | Requirement |
|--------|-------------|
| Form | A **clean, linear document** — identical in content and section order to today's PDF (FR-005, SC-004). |
| Screen chrome | Sticky nav, card borders/shadows/backgrounds, and animations are **absent** (nav `display:none`/static; cards flattened; `animation/transition: none`). |
| Pagination | Experience/competition entries use `break-inside: avoid` so a single entry is not split across pages. |
| Cross-link | The **QR code** back to the page is present (FR-006). |
| Generation | Produced by the **unchanged** `src/utils/pdf.js` (`page.pdf()`, default print media, A4, `page.pdf({margin})`). **No `emulateMedia` call** is added. |

## Animation class contract

- Elements that scroll-reveal carry the class **`.reveal`**.
- Default (no JS) and reduced-motion state is **fully visible** — the hidden state is gated behind a
  JS-set **`.js`** root class **and** `@media (prefers-reduced-motion: no-preference)`, so content is
  never left `opacity:0` if JS fails.
- `reveal.js` adds `.is-visible` (one-shot) to animate; `@media print` forces `.reveal` visible +
  no motion; the test-only `tests/snapshot.css` forces `.reveal` to its final state for deterministic
  snapshots.

## Invariants across both

- Same content, same order (content parity, SC-004).
- One template, one CSS file; no separate print template; no `pdf.js` change.
- Vendored fonts only (no CDN) — required for deterministic snapshots and offline builds.
- **Static-only (FR-010)**: no backend/DB/API is introduced; the site still deploys as a static
  artifact on the existing platform.
- **Workflows intact (FR-012)**: local development and the existing build + deploy flows
  (`npm start`, `make page`, `make dev-build`, the Vercel deploy) continue to work unchanged.
