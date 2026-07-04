# Research: interactive editorial deck (Phase 0)

Technical + design decisions for the re-spec'd feature 003 (full-viewport deck + summary-card rails +
detail overlays + editorial restyle). Each decision is **Decision / Rationale / Alternatives**. Most
were validated in the throwaway prototype (`003-proto`, owner-confirmed); the open ones were resolved
by targeted research (fonts, signature, nested-scroll, dialog a11y).

## D1 — Scroll mechanism: native CSS Scroll Snap deck (NOT a JS scroll-jacker)

- **Decision**: The vertical "deck" uses **native CSS Scroll Snap** — `html { scroll-snap-type: y
  mandatory }`, and each panel (`header`, `.cv-section`) `scroll-snap-align: start; scroll-snap-stop:
  always`. Wheel/trackpad/touch are 100% browser-driven. Keyboard section nav is a **thin JS layer**
  (`scrollIntoView({behavior})`) that coexists with snap; it does **not** intercept wheel/touch.
- **Rationale**: The prototype first hand-rolled a `requestAnimationFrame` wheel/touch scroll-jacker;
  it fought macOS trackpad momentum (a swipe emits ~40+ non-cancelable inertial `wheel` events) →
  sluggish/flickering start that no tuning removed. Switching to native snap fixed it in less code
  (owner: "works perfectly"). Codified in [`docs/interaction-gotchas.md`](../../docs/interaction-gotchas.md).
- **Alternatives**: JS scroll-jacker (rejected — the failure above); `fullPage.js` (GPLv3 would
  relicense the repo + same Mac bug); Swiper (Mac "jumps 2 slides" bug, weak no-JS).

## D2 — Deck breakpoint scope & reduced motion

- **Decision**: The deck applies at **all breakpoints**, but a panel whose content **exceeds the
  viewport** (chiefly small phones) relaxes so it scrolls internally (mandatory snap is native-exempt
  for over-viewport snap areas). Under `prefers-reduced-motion`, **snapping is kept** (a resting
  position, not animation) while the smooth glide + overlay/emphasis transitions are **suppressed**.
- **Rationale**: Primary audience is a recruiter on a phone, so the deck should hold on mobile; but
  mandatory snap only suits uniform ~viewport panels (gotchas doc), so tall panels must relax to avoid
  trapping content. Reduced-motion: snapping is a rest state, safe to keep; only the tween is gated
  (matches the prototype + gotchas guidance). Confirmed via `/speckit-clarify` (2026-07-04).
- **Alternatives**: snap only ≥ md (drops the deck for the phone-first audience); mandatory everywhere
  unconditionally (clips tall content); fully disable snap under reduce (loses the rest-on-section
  wayfinding it gives for free).

## D3 — Content-dense sections: summary-card rails → full-screen detail overlay

- **Decision**: Professional Experience, Additional Experience, Robotics Competitions render as
  **horizontal rails** (`overflow-x:auto; scroll-snap-type: x mandatory`, peek of the next card) of
  **short summary cards** (period, title, teaser). Activating a card opens the **full entry in a
  full-screen overlay** — a focused card on a dimmed/blurred backdrop.
- **Rationale**: Short cards keep each rail scannable and each deck panel ~one viewport; long content
  goes to the overlay instead of an unintuitive in-card scroll (the rejected original UX). Validated in
  the prototype.
- **Alternatives**: long scrolling cards (rejected — the original UX the owner disliked); expanding a
  card in place (breaks the deck panel height / snap).

## D4 — Nested scrolling: a horizontal rail inside a vertical snap panel

- **Decision**: Keep both axes native and isolate them with **`overscroll-behavior`**: the rail sets
  `overscroll-behavior: contain` (already `overscroll-behavior-x: contain` in the prototype) plus
  `touch-action: pan-x pan-y` as hardening. The rail owns X; the deck owns Y; neither chains into the
  other. Do **not** set `overscroll-behavior` on the root deck. The flex/scroll item must be the
  `<li>`, not the inner `<a>`.
- **Rationale**: `overscroll-behavior-x: contain` stops an X-fling from chaining to the deck and
  triggering a panel snap, while a genuinely vertical gesture still reaches the deck. Scroll snapping is
  per-axis per-container, so an `x` rail inside a `y` deck does not cause diagonal/"between-panels"
  snapping (panels are uniform ~100vh + `scroll-snap-stop: always`). The prototype already works this
  way; the additions are defensive. Consistent with the gotchas rule (no wheel/touch jacking).
- **Alternatives**: `touch-action: none` + JS gesture routing (a scroll-jacker by another name —
  rejected); `proximity` on the rail (unnecessary; cards are uniform and shorter than the track).

## D5 — Detail overlay accessibility: `:target` no-JS baseline + dialog PE

- **Decision**: Baseline is CSS **`:target`** (summary card `<a href="#pN">`; overlay `#pN:target`;
  close links `<a href="#experience">`; `body:has(.proto-detail:target){overflow:hidden}` locks scroll)
  — works with **no JS**. Layer dialog semantics on top as progressive enhancement (only when JS runs):
  static `role="dialog" aria-modal="true" aria-labelledby`, a **visible** close control, and JS on
  `hashchange` to **move focus in / trap it / return it to the triggering card**, mark the background
  `inert` (fallback `aria-hidden`), and **Escape-to-close** (routing through `location.hash='experience'`,
  the same target the links use).
- **Rationale**: `:target` gives open/close/scroll-lock/Back-button for free with no JS; the one thing
  it cannot do — focus management — is exactly the a11y gap, added minimally via the hash state machine
  (every open/close path flows through the hash, so one listener covers all). Nothing added breaks the
  no-JS path. `inert` removes the background from tab order + a11y tree (feature-detected).
- **Alternatives**: native `<dialog>` + `showModal()` (no no-JS fallback — rejected as baseline; could
  be a further enhancement); full JS click-handler modal (throws away the no-JS baseline + Back button).
- **Pitfall**: `<base target="_blank">` silently breaks in-page anchors — **every** overlay anchor
  (card, backdrop, visible close) MUST set `target="_self"` (gotchas doc; bit 002 nav + 003 cards).

## D6 — Editorial design system (screen-only)

- **Decision**: Reference theopenengine.com. **Type**: Fraunces (variable display serif, optical-size
  tracked) for headings; Spline Sans (variable) for body. **Palette tokens**: `--p-cream #FAF7F1`
  (bg), `--p-ink #0F172A` (headings), `--p-slate #475569` / `--p-slate-2 #64748B` (body), `--p-terra
  #C2240C` (accent). **Layout**: no boxy cards; small uppercase terracotta **eyebrow** labels above
  section titles (`data-eyebrow`); generous type scale (`clamp()`), airy spacing. **Skills**: compact
  chips filled to each skill's proficiency %. All under `@media not print` — the PDF keeps Roboto/linear.
- **Rationale**: Validated in the prototype and owner-approved; encodes a distinctive editorial identity
  without touching the PDF (screen/print split from 002).
- **Alternatives**: keep the 002 Roboto/Bootstrap look (rejected — the restyle is core to the validated
  design); a heavier framework/theme (violates vanilla/minimal).

## D7 — Vendored fonts (no CDN at render time)

- **Decision**: Self-host via **`@fontsource-variable/fraunces`** (ship `opsz.css` + latin woff2) and
  **`@fontsource-variable/spline-sans`** (ship `wght.css` + latin woff2), added as **devDependencies**
  and copied from `node_modules` into `dist/vendor/` by the existing `vendoredAssets` loop in
  `src/build.js` — byte-for-byte the pattern Roboto already uses (#24, no CDN). Reference the families
  **only inside the `@media not print` block** in `styles.css` (Bootstrap `--bs-font-sans-serif` →
  `'Spline Sans Variable', roboto, sans-serif`; headings → `'Fraunces Variable', serif;
  font-optical-sizing: auto`). `@media print` is untouched → the PDF stays Roboto.
- **Rationale**: Matches the vendored-asset invariant (no third-party request at render time), keeps
  `dist/` generated, needs no Makefile/CI change (`build.js` copy loop picks new files up). Both fonts
  are **OFL-1.1** (self-hosting permitted). `font-display: swap` is already set in both packages
  (FOUT, no invisible text). Roboto stays the fallback so screen degrades safely mid-load.
- **Alternatives**: Google Fonts CDN (violates #24 / offline PDF); committing static woff2 under
  `src/assets` (diverges from the Roboto precedent, bloats git); non-variable `@fontsource/*` (needs
  multiple weight files — the variable package is leaner).
- **Note**: fonts are screen-only, so they change the **screen** baselines (intentional →
  `make visual-update`, reviewed); the **PDF** baseline must stay unchanged — if it moves, the
  screen-only scoping leaked into print.

## D8 — The signature: "The Through-Line"

- **Decision**: A single continuous **terracotta thread down the left margin of the whole deck**, with
  one node per section; as each section snaps in, the thread's fill advances to that section's node and
  the current node fills terracotta. It doubles as the section-nav/progress spine (so it adds net-zero
  chrome), `position: fixed` in the gutter (CLS ≈ 0), `.screen`-classed (absent from the PDF via the
  existing `@media print { .screen { display:none } }`).
- **Rationale**: An engineering manager from distributed-systems / dispatch-routing — "a route with a
  live node advancing one hop at a time" is his domain, rendered as one editorial hairline (not a
  diagram). It tracks the deck's **primary axis** (one node per snap), so the signature and the
  "one gesture = one section" mechanic are the same motion — the right scale. Spends boldness once
  (one terracotta accent against cream); reuses existing section IDs + the `--p-terra` token.
- **PE / reduced-motion / no-JS**: JS (reusing the deck's section-observer) sets `--progress` +
  `aria-current` + an `aria-live` "Section N of M". No-JS: a static hairline with plain anchor-dot
  jump links (fail-visible, like `reveal.js`). Reduced-motion: the fill/active node **jump** (state
  shown, tween suppressed). Only compositor-friendly props animate → no layout shift.
- **Alternatives**: the rejected per-rail "route between nodes" indicator (built for the rails paradigm;
  tracks a secondary axis, reads infographic — superseded); a hero typographic reveal (fires once, risks
  FOUT/CLS); plain progress dots (generic; drops the routing tie-in).

## D9 — Deterministic snapshots + the visual/PDF gate

- **Decision**: Extend the existing Playwright visual + PDF gate. Capture a **deterministic resting
  state**: scroll to top (deck on the hero), fonts ready, no overlay open (`:target` cleared),
  reduced-motion forced (existing `tests/snapshot.css` + config). Regenerate the six **screen**
  baselines (intentional restyle → `make visual-update`, reviewed). The **PDF** visual baseline (added
  in #164) MUST stay unchanged — it is the guardrail proving the restyle/deck is screen-only.
- **Rationale**: The restyle deliberately changes every screen pixel, so screen baselines must be
  re-generated; the PDF staying byte-identical is the machine-checked proof of SC-005 (PDF unchanged).
- **Alternatives**: snapshot mid-scroll / overlay-open states (non-deterministic — rejected for the
  committed baseline; may be added as separate, explicitly-driven states later).

## D10 — Progressive enhancement / no-JS posture

- **Decision**: The whole feature degrades without JS: the deck still snaps (pure CSS), rails stay
  horizontally scrollable strips, detail overlays open/close via `:target`, the Through-Line is a static
  index of jump links. JS is **additive only**, gated by an `.js` class on `<html>` set before first
  paint (the `reveal.js` precedent), and enriches: keyboard section nav, overlay focus management + Esc,
  the Through-Line fill/`aria-current`, and the `.reveal` opacity fade.
- **Rationale**: Constitution + spec (FR-011/SC-003) require 100% content reachable with no JS; the
  `.js`-gate "fail visible" pattern is already established (`reveal.js`).
- **Alternatives**: JS-required interactions (rejected — violates progressive enhancement).

## Meta-note

The editorial design system (D6) and the signature (D8) supersede the stale `design.md` from the
original rails-era 003; that file is removed and its concerns folded here. The concrete DOM/ARIA and
screen/print obligations are captured in [`contracts/interaction-contract.md`](contracts/interaction-contract.md).
