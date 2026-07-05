# 0004 — Interactive CV as a native-scroll-snap editorial deck

- **Status:** Accepted — implemented across the `003-interactive-card-rails` milestone (US1 deck,
  US2 rails + detail overlays, US3 editorial restyle, US4 accessibility, US5 Through-Line; integration
  #222) and refined by the Skills rework (#226)
- **Date:** 2026-07-05

## Context

The 002 redesign ([ADR 0003](0003-visual-regression-and-screen-print-decoupling.md)) gave the screen a
card/section layout with a sticky nav and a subtle scroll-reveal, and — crucially — a
**visual-regression + PDF gate** plus a **screen/print CSS decoupling** that lets the on-screen page be
rich while the PDF stays a clean, linear document. That decoupling was explicitly built as "the
platform for future screen-only interactivity."

003 spends that platform: make the digital CV distinctly more engaging and memorable — a bold,
interactive experience — **without** touching the PDF, the content model (`metadata.js`), or the
static, no-backend build.

Forces:

- The experience must be **memorable but disciplined** — one signature moment, not novelty everywhere.
- Content-dense sections (Experience, Additional, Competitions, and later Skills) are long lists;
  scrolling a wall of them is dull. They should be **flick-through** on touch and fully navigable by
  keyboard and pointer.
- **Progressive enhancement is non-negotiable:** no content may hide behind a gesture; everything must
  work with no JavaScript, respect `prefers-reduced-motion`, and be keyboard- and screen-reader-usable.
- The page itself must **never scroll horizontally** — rails scroll within their own track.
- The **PDF stays byte-identical** and the visual + PDF gate keeps guarding it.
- Stay **vanilla** — HTML/CSS + light progressive-enhancement JS; no framework; Handlebars retained.

## Decision

Build the screen as a **full-viewport scroll-snap "deck"** of editorial panels, with content-dense
sections as **card rails** that open **detail overlays**, one **signature** motion, and everything
**screen-only** so the PDF is untouched.

1. **Native CSS Scroll Snap deck.** `scroll-snap-type: y mandatory` on `<html>`, each section/hero at
   `min-height: 100vh` with `scroll-snap-align: start; scroll-snap-stop: always`. The browser owns
   wheel/trackpad/touch momentum — **no scroll-jacking JS** (a hand-rolled scroller fights native
   momentum; see [interaction-gotchas.md](../interaction-gotchas.md)). `deck.js` only upgrades
   **keyboard** nav to one-section-per-press and drives the Through-Line; tall panels relax to
   top-alignment (`justify-content: safe center`) so nothing is clipped.
2. **Summary-card rails + `:target` detail overlays.** Each dense section is a horizontal `.cv-rail` of
   short `.cv-summary` cards (`overflow-x: auto; scroll-snap-type: x mandatory; overscroll-behavior:
   contain`, so a rail fling never disturbs the vertical deck). A card is an `<a href="#id">`; the
   overlay is `<div id="id" class="cv-detail">` shown via `:target` — **open / close / scroll-lock /
   backdrop are pure CSS and work with no JS.** `overlay.js` layers dialog semantics on top (focus
   trap/return, Escape, `aria-modal`). A pure-CSS **swipe affordance** (right-edge fade + chevron) hints
   the rails scroll.
3. **The "Through-Line" signature.** A single fixed left-gutter progress thread that fills as you snap
   through the deck — the one memorable moment, disciplined and screen-only (hidden below 768px).
4. **Editorial restyle, screen-only.** Vendored **Fraunces** + **Spline Sans** (no CDN, applied
   `media="screen"`), a warm palette, and eyebrow labels; Skills became category-card rails (#226)
   instead of a proficiency-chip wall.
5. **PDF isolation via `emulateMedia`.** `src/utils/pdf.js` now calls
   `page.emulateMedia({ media: 'print' })` **before** navigating, so screen-only rules and the
   `media="screen"` webfonts are never applied or even fetched for the PDF. **This reverses ADR 0003's
   "`pdf.js` is unchanged (no `emulateMedia`)" decision:** with a screen this rich, relying on
   Chromium's default print emulation was too easy to break silently; making `pdf.js` assert print
   media is a small, deterministic guarantee that the PDF renders exactly the print document.

## Alternatives considered

- **A JS scroll-jacking library (fullPage.js-style).** Rejected: fights native trackpad/touch momentum
  (the exact thrash hit while prototyping), adds weight, and breaks the no-JS baseline. Native
  scroll-snap gives the "rest on a section" feel for free.
- **Keep the 002 vertical page, just bolt on the rails.** Rejected: the deck is what makes it feel like
  an *experience*; the brief was memorable, not incremental.
- **JS-driven overlays (a modal library, or `<dialog>` only).** Rejected: the `:target` baseline works
  with no JS and is what the PDF path relies on; `<dialog>`/JS are the enhancement, not the foundation.
- **A separate print template, or leaving `pdf.js` on default media.** Rejected: one template keeps
  content parity by construction; default-media print proved fragile once the screen carried its own
  fonts and a 100vh deck — hence the `emulateMedia` guarantee.
- **Proficiency bars / a chip wall for Skills.** Rejected during #226: self-rated percentages read
  junior and the chip wall overflowed on mobile; category-card rails reuse the same components and read
  better.

## Consequences

- **Positive:** a distinctive, accessible screen experience that reuses one rail/overlay vocabulary
  across every dense section; the PDF is provably the print document (`emulateMedia` + the pixel gate);
  the no-JS, reduced-motion, and keyboard paths all work by construction.
- **Negative / trade-offs:** more screen-only CSS/JS to maintain; the deck's `100vh` panels make the
  **fullPage** visual snapshots tall, so a single-section change can fall under the gate's
  `maxDiffPixelRatio` at wide widths (found via a Skills near-miss — tracked as #225); the swipe
  affordance persists at a rail's scroll-end (an accepted pure-CSS trade-off). Decision 5 amends ADR
  0003's decision 2.
- **Follow-ups:** tighten or replace the fullPage visual budget so section-scoped changes always
  register (#225); the gate weaknesses around fixed chrome (#221) and the `make visual` dev-watch race
  (#223) remain open.
