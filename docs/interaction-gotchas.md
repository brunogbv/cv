# Interaction gotchas (scroll / anchors)

A short, reusable checklist for **interaction-heavy** changes on this site — scroll-snap decks,
rails, in-page navigation, card/detail flows. These are cross-cutting learnings (symptom → cause →
rule), not a diary of any one feature; read them **before** building anything with programmatic
scrolling or scroll-snap, so the next such change doesn't re-discover them from scratch.

For the code structure these interactions plug into (the template, `styles.css`, the progressive-
enhancement scripts, the screen/print split), see [architecture.md](architecture.md).

## Scroll-snap ↔ programmatic scroll

> **Headline rule (learned the hard way in the 003 prototype): for a full-viewport "deck," use
> _native_ CSS Scroll Snap and do NOT hand-roll a wheel/touch scroll-jacker.** A JS scroll-jacker
> (intercept `wheel`/`touch`, animate `scrollTop` to the next index) inescapably **fights the
> platform's own scroll momentum** — most visibly a macOS trackpad, where one two-finger swipe emits
> ~40+ inertial `wheel` events with _no_ momentum-phase signal and events that aren't reliably
> cancelable. The result is a sluggish, flickering start that no amount of tuning removes (we tried
> rAF glides, momentum locks, pin-to-target — all treat the symptom). Native snap sidesteps it
> entirely: the browser composits the scroll and applies snapping on its own thread. Hand-rolled
> scroll-jacking is also [widely discouraged for usability](https://www.nngroup.com/articles/scrolljacking-101/).

**What actually works — a native deck (screen-only, so the PDF/print flow is untouched):**

```css
@media not print {
  html { scroll-snap-type: y mandatory; }
  .deck-section {                 /* each panel is ~one viewport tall */
    min-height: 100vh;
    scroll-snap-align: start;
    scroll-snap-stop: always;     /* a hard flick advances exactly ONE panel, never skips */
    scroll-margin-top: 0;         /* land exactly on the panel top (see anchors, below) */
  }
}
@media (prefers-reduced-motion: no-preference) { html { scroll-behavior: smooth; } }
```

- **Native snap gives one-panel-per-flick for wheel / trackpad / touch by itself.** With
  `mandatory` + `scroll-snap-stop: always` on uniform ~viewport-height panels, the browser rests on a
  panel or animates to the neighbour and **cannot land between or skip** — the two states you want,
  with zero JS. `scroll-snap-stop: always` is [Baseline / ~94%](https://caniuse.com/mdn-css_properties_scroll-snap-stop)
  (Chrome/Edge, Safari 15+, Firefox 103+) — the older "Safari/Firefox don't support it" advice is stale.

- **The one thing snap does _not_ cover is the keyboard** — Arrow / PageUp-Down do a small native
  step, not a full panel. Add a **thin, orthogonal** JS layer only for that: on keydown, find the
  current panel and call `neighbour.scrollIntoView({ behavior: reduce ? 'auto' : 'smooth' })`. This
  **coexists with `mandatory` snap** — CSS smooth-scroll and snap control orthogonal things and are
  designed to work together; snapping runs _after_ a programmatic scroll settles. Keep this layer to
  keyboard only; do **not** intercept `wheel`/`touch` (that's the scroll-jacker the headline rule
  forbids). It's pure progressive enhancement — with no JS the native snap still works.

- **Where the "CSS snap fights JS smooth-scroll hiccup" really comes from.** It is specifically CSS
  `mandatory` snap fighting a JS scroll _you animate frame-by-frame or via `scrollTo({behavior})`_:
  the browser force-snaps mid-animation and the glide lands wrong, then jumps. That is an argument to
  **stop animating the scroll yourself**, not to abandon snap. Snap + native anchor/`scrollIntoView`
  navigation do not fight (the browser reconciles them).

- **`mandatory` snap on panels taller than the viewport feels laggy.** `mandatory` always pulls to the
  nearest snap point, so on over-one-viewport panels it fights the user's own scroll and feels
  sticky/heavy. **Rule:** reserve `mandatory` for a deck of **uniform, ~viewport-height** panels. For
  anything that can exceed the viewport, use `proximity` (snaps only when already close) or no snap,
  and let it scroll normally.

**Libraries (evaluated during the 003 discovery — none warranted here).** For "centered, or animating
to the neighbour," native CSS is the right tool — 0 bytes, no dependency, no-JS fallback, print-safe.
Two turnkey options were rejected on this project's constraints: **fullPage.js** — its free tier is
**GPLv3**, which would force this whole repo to be relicensed GPLv3 (or pay), _and_ it carries the
same documented macOS-trackpad over-scroll bug; **Swiper** (MIT) — documented Mac-trackpad "jumps 2
slides" bug (esp. Safari) and a weak no-JS story. A library is only worth it for things CSS can't do
(cross-panel scroll-triggered animation orchestration, combined H+V decks, per-panel URL hashes,
fine easing control) — none of which a section deck needs.

## In-page anchors

- **`<base target="_blank">` silently breaks every in-page anchor.** A page-wide
  `<base target="_blank">` (added so external links open in a new tab) also applies to `href="#…"`
  links — nav links, card links, close/back buttons, "skip to content". Each one then opens a **new
  tab and reloads the whole page** instead of jumping within the current page. It fails _silently_ —
  nothing errors; the anchor just misbehaves.
  **Rule:** any in-page anchor (`href="#…"`) under a `<base target="_blank">` must set
  `target="_self"` explicitly. This bit the 002 section nav and again the 003 card links — treat it
  as a standing checklist item whenever you add anchors. (Also noted in the template section of
  [architecture.md](architecture.md).)

## Reduced motion

- Any **JS** scroll (`scrollTo`/`scrollIntoView` with `behavior: 'smooth'`) overrides the CSS
  `scroll-behavior` setting and ignores `prefers-reduced-motion`. Branch on
  `matchMedia('(prefers-reduced-motion: reduce)')` and pass `behavior: 'instant'` (or `'auto'`) when
  reduce is set. Scroll-_snapping_ itself is a resting position, not animation — keep it on; it's the
  animated glide you gate.

## A note on ADR 0004

The interactive redesign (feature 003) is **not yet decided or built** — a re-spec is pending — so
there is no chosen approach to record. When the 003 interactive build lands, capture the approach it
settles on as **ADR 0004** in [adr/](adr/). This note is the reusable gotcha list, not that decision
record.
