# Interaction gotchas (scroll / anchors)

A short, reusable checklist for **interaction-heavy** changes on this site — scroll-snap decks,
rails, in-page navigation, card/detail flows. These are cross-cutting learnings (symptom → cause →
rule), not a diary of any one feature; read them **before** building anything with programmatic
scrolling or scroll-snap, so the next such change doesn't re-discover them from scratch.

For the code structure these interactions plug into (the template, `styles.css`, the progressive-
enhancement scripts, the screen/print split), see [architecture.md](architecture.md).

## Scroll-snap ↔ programmatic scroll

- **CSS scroll-snap fights JS-driven smooth-scroll.** With `scroll-snap-type: … mandatory` on a
  container *and* JavaScript that animates a scroll (section nav, prev/next, "scroll to card"), the
  browser force-snaps mid-animation to the nearest snap point — the animation lands on the wrong
  place, then jumps (the "hiccup").
  **Rule:** pick **one** mechanism. Either CSS snap *or* JS-driven scrolling drives a given axis —
  not both on the same container.

- **`mandatory` snap on sections taller than the viewport feels laggy.** `mandatory` always pulls to
  the nearest snap point, so on tall (over-one-viewport) sections it fights the user's own scroll and
  feels sticky/heavy.
  **Rule:** reserve `mandatory` for a "deck" of **uniform, ~viewport-height** panels. For anything
  that can exceed the viewport, use `proximity` (snaps only when you're already close) or no snap.

- **`scroll-snap-stop: always` does not give you one-section-per-gesture.** It only forces a stop at a
  snap point *once you reach it*; it doesn't intercept the native incremental Arrow-key / wheel /
  trackpad scroll that steps *between* snap points. So arrow keys still land mid-section.
  **Rule:** if you truly need exactly one section per keypress/gesture (a true deck), that's a
  **JS** concern (capture the key/wheel, animate to the next index) — and then it's JS-driven
  scrolling, so per the first rule, don't also put `mandatory` snap on that container.

Corollary: a clean scroll-snap "deck" wants uniform, roughly viewport-height panels and a single
scroll driver. If the content can't be uniform or the sections must be taller than the viewport,
prefer plain scrolling (optionally `proximity`) over forcing a deck.

## In-page anchors

- **`<base target="_blank">` silently breaks every in-page anchor.** A page-wide
  `<base target="_blank">` (added so external links open in a new tab) also applies to `href="#…"`
  links — nav links, card links, close/back buttons, "skip to content". Each one then opens a **new
  tab and reloads the whole page** instead of jumping within the current page. It fails *silently* —
  nothing errors; the anchor just misbehaves.
  **Rule:** any in-page anchor (`href="#…"`) under a `<base target="_blank">` must set
  `target="_self"` explicitly. This bit the 002 section nav and again the 003 card links — treat it
  as a standing checklist item whenever you add anchors. (Also noted in the template section of
  [architecture.md](architecture.md).)

## Reduced motion

- Any **JS** scroll (`scrollTo`/`scrollIntoView` with `behavior: 'smooth'`) overrides the CSS
  `scroll-behavior` setting and ignores `prefers-reduced-motion`. Branch on
  `matchMedia('(prefers-reduced-motion: reduce)')` and pass `behavior: 'instant'` (or `'auto'`) when
  reduce is set. Scroll-*snapping* itself is a resting position, not animation — keep it on; it's the
  animated glide you gate.

## A note on ADR 0004

The interactive redesign (feature 003) is **not yet decided or built** — a re-spec is pending — so
there is no chosen approach to record. When the 003 interactive build lands, capture the approach it
settles on as **ADR 0004** in [adr/](adr/). This note is the reusable gotcha list, not that decision
record.
