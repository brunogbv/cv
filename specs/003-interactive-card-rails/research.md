# Research: interactive swipeable card rails

Phase 0 decisions. Grounded in the WAI-ARIA APG, MDN, web.dev, Playwright docs, and a11y practitioners
(Adrian Roselli, Sara Soueidan, Ahmad Shadeed). Each: **Decision / Rationale / Alternatives**.

## D1 — Rail semantics: labelled scrollable region + list (not the APG carousel widget)

- **Decision**: Build each rail as a **labelled, focusable, scrollable `region`** (`role="region"` +
  `aria-label`, or `role="group"`) wrapping a plain `<ul>`/`<li>` of cards. No `aria-roledescription`,
  no tablist slide-picker, no play/pause.
- **Rationale**: The APG "carousel" pattern targets **auto-rotating, JS-driven slideshows** with
  scripted controls; a no-JS scroll-snap strip has all cards present and user-scrollable, so
  carousel/slide/tab roles would mislabel it and imply behaviors it lacks. A region + `<ul>` exposes
  what it is — a named area containing a countable, ordered list (SR announces "list, N items" +
  position). `aria-roledescription` has patchy AT/localization support.
- **Alternatives**: Full APG carousel (overkill, mislabels a static rail); native CSS Carousels
  (`::scroll-marker`/`::scroll-button()`) — Chromium-only (135+), documented ARIA defects for
  multi-item rails → **enhancement only, never baseline**.

## D2 — Keyboard focus: `tabindex="0"` on the scroll container; don't tabindex cards

- **Decision**: Put `tabindex="0"` + `role`/`aria-label` on the **scroll container** so keyboard users
  can Tab to it and arrow-scroll in every browser. Do **not** add `tabindex` to cards — rely on the
  real links inside them; keep off-screen cards in normal flow and the tab order. Add
  `scroll-padding` so a focused/snapped card lands inside the track and its focus ring isn't clipped.
- **Rationale**: A scroll container is **not** universally keyboard-focusable — Chromium only added
  auto-focusable scrollers in 132 (2025), and **Safari/WebKit still doesn't** — so an explicit
  `tabindex="0"` is the portable fix. A focusable element needs a name+role (WCAG 4.1.2), hence the
  region+label. Bare `tabindex` on cards adds nameless focus stops; real links are already correctly
  in the tab order. `overflow` can clip an edge card's focus ring (WCAG 2.4.7 / 2.4.11), which
  `scroll-padding` + gutter + `outline-offset` fix.
- **Alternatives**: Rely on Chromium auto-focusable scrollers (not portable — Safari); `tabindex="-1"`
  on cards (useless with no JS to move focus); `inert` off-screen cards via `scroll-state()` (Chromium
  only, and Chrome warns it breaks SR item counts for list rails).

## D3 — Progressive enhancement: CSS-only baseline, JS additive-only

- **Decision**: The no-JS baseline is a horizontally scrollable, snapping strip with **all cards in the
  DOM and reachable** (swipe / trackpad / keyboard). `src/assets/rails.js` adds only *affordances* —
  prev/next controls, the position/route indicator, and an `aria-live` position status — layered on
  top. Content is **never** hidden behind JS.
- **Rationale**: Snap + overflow are pure CSS (web.dev/MDN); content is plain HTML. Mirrors the 002
  `reveal.js` "fail visible" principle: JS improves ergonomics, never gates access.
- **Alternatives**: JS-mounted carousel (content vanishes without JS — rejected); native CSS
  marker/button controls (Chromium-only — use as an optional extra, not the affordance baseline).

## D4 — Peek + snap mechanics (CSS)

- **Decision**: Container: `overflow-x: auto; scroll-snap-type: x mandatory; scroll-padding-inline:
  <gutter>; overscroll-behavior-x: contain`. Cards: `flex: 0 0 clamp(<min>, <sub-100%>, <max>);
  min-width: 0; scroll-snap-align: start`. Keep a (thin) scrollbar or provide an equivalent
  "there's-more" affordance (the peek + route indicator serve this). Use **logical** properties
  (`scroll-padding-inline`, `inline` axis) for RTL-safety.
- **Rationale**: `scroll-snap-type: x mandatory` + `scroll-snap-align` is the canonical mechanism;
  `mandatory` suits per-card snapping. A sub-100% card basis makes the next card **peek**;
  `scroll-padding-inline` turns the remainder into a stable gutter. `min-width: 0` is essential — the
  default `min-width: auto` refuses to shrink and would overflow the **page** (violating SC-002).
  `overscroll-behavior-x: contain` stops scroll-chaining to the page / swipe-nav at the rail ends.
- **Alternatives**: `proximity` snap (softer; better only for cards taller than the viewport — keep
  `mandatory` here but see edge cases); `scroll-snap-align: center` (symmetric peeks — `start` chosen
  for a left-aligned rail with one trailing peek); hiding the scrollbar with no replacement (rejected —
  removes an affordance/operability, WCAG 2.1.1).

## D5 — Reduced motion: keep snapping, gate only the smooth glide

- **Decision**: Snapping stays on always; gate only the animated smooth-scroll glide behind
  `@media (prefers-reduced-motion: no-preference) { html { scroll-behavior: smooth } }`. Any
  JS-driven prev/next scroll MUST branch on `matchMedia('(prefers-reduced-motion: reduce)')` (an
  explicit `behavior:'smooth'` in `scrollTo` overrides CSS and ignores the preference).
- **Rationale**: Snapping is a resting-position behavior, not animation; the motion to suppress is the
  glide. Instant-as-fallback (the `no-preference` gate) means older/unmatched UAs get the safe
  behavior. WCAG 2.3.3.
- **Alternatives**: Disabling `scroll-snap-type` under reduced-motion (wrong — kills a useful,
  non-animated behavior); inverse `@media (reduce)` form (works, but `no-preference` gating makes the
  accessible path the default).

## D6 — Deterministic snapshots for the gate

- **Decision**: In the visual spec, before asserting a rail: set `history.scrollRestoration =
  'manual'`, reset the rail's `scrollLeft = 0` (or `scrollIntoView({behavior:'instant'})` a chosen
  card), disable smooth scroll, `await document.fonts.ready`, and normalize the scrollbar consistently.
  Keep Playwright defaults (`animations:'disabled'`, `caret:'hide'`) and allow a small
  `maxDiffPixelRatio`/`threshold` for subpixel snap jitter. Generate baselines in the **pinned
  Playwright image** (as today), never the host.
- **Rationale**: Snap containers re-snap to the previously snapped element and `scrollRestoration`
  defaults to `auto`; a screenshot mid-smooth-scroll catches a between-snap frame; `animations:
  'disabled'` does **not** cover scrolling. Subpixel snap positions cause 1px edge diffs, absorbed by
  tolerance. Matches this repo's container-first determinism (002).
- **Alternatives**: `stylePath` masking of volatile bits (already used via `tests/snapshot.css` — extend
  if needed); snapshot the rail element rather than full page (keep full-page for consistency with 002,
  add per-rail only if jitter demands).

## D7 — Design accent & type discipline (frontend-design pass — see design.md)

- **Decision**: **No new color and no new font.** Keep the neutral base (ink/gray/white) and reuse the
  existing skill-bar **red as the single "signal/active" accent**; spend the boldness on the
  interaction/**signature form**, not a new palette. Keep Roboto (PDF + body) with a stronger,
  intentional screen type scale rather than adding a display face.
- **Rationale**: frontend-design's "spend boldness in one place" + constitution Principle V (minimal,
  pin what determines output). A new color/font would touch the PDF or add vendored weight for little
  gain; the routing signature carries the personality. Avoids the generic AI-default palettes.
- **Alternatives**: A second accent (indigo) for the route signature (rejected — two accents clutter,
  the reused red already reads as "the live signal"); a screen-only display face (rejected — extra
  vendored font, more baseline churn; Roboto at a deliberate scale suffices).

## D8 — The signature: "route between nodes" (justified sequence indicator)

- **Decision**: The distinctive moment is each rail's **position/progress rendered as a route between
  nodes** — the cards as ordered nodes on a connected route line, the active card the filled "live"
  (red) node — doubling as the rail's position affordance and `aria-live` target.
- **Rationale**: frontend-design says structural devices (numbering/markers) must encode something
  *true*: a rail **is** an ordered sequence, so a position/route indicator is content-justified (not
  decorative). It ties directly to the subject's distributed-systems / dispatch-routing domain,
  concentrates the boldness in one memorable element, and solves the a11y "where am I / there's more"
  need. Screen-only (absent in the PDF).
- **Alternatives**: Plain carousel dots (generic, fails the "is this a choice for *this* brief" test);
  a full-screen hero deck (rejected earlier — Direction B chosen); numbering without the route line
  (loses the domain metaphor).

## Meta-note (from research)

Practitioners (Roselli) caution that users pattern-match horizontal rails to "marketing carousels" and
skip them. Our mitigations directly address this: the **sticky section nav still jumps to sections**
(rails aren't the only way to content), the **route indicator makes position + "there's more"
explicit**, and content is never hidden. Keep a deliberate "does this section benefit from a rail?"
check — hence rails are limited to the three genuinely multi-entry, content-dense sections.
