# Design direction: interactive card rails

Produced with the **frontend-design** methodology (design-lead pass): a compact token system + the one
signature element, deliberately avoiding generic "AI-default" looks. Intent-level; exact values are
finalized at implementation and locked by the visual gate.

## Brief, grounded in the subject

The subject is an **Engineering Manager in distributed systems / reactive architecture**, who built
and led **dispatch/routing** platforms (Delivery Hero, Flink) and competed in **rescue robotics**. The
page's job: a fast, credible, *memorable* impression for a recruiter (often on a phone). The design
thesis is the subject's own world: **a system of nodes you route between.** Cards are nodes; moving
through a rail is routing between them. That metaphor — not a templated portfolio shell — is where the
distinctiveness comes from.

## Token system

### Color — reuse, don't repaint

Keep the existing neutral base and the existing red; **no new hue** (keeps the PDF identical and spends
boldness on the interaction, per Principle V + frontend-design's "one bold place").

| Token | Value | Role |
|-------|-------|------|
| `ink` | `#000` | headings |
| `body` | `#595959` / `#858585` | text (AA-safe for interactive, existing scale for prose) |
| `surface` | `#fff` | cards |
| `page` | `#fff` (unchanged from 002) | page background |
| `line` | `var(--light-color)` `#D9D9D9` | hairlines, inactive route nodes |
| `signal` | the existing skill-bar **red** | the **active/live** accent: filled route node, focus/affordance emphasis |

The red already means "signal strength" in the skill bars; reusing it as the **live node** on the
route unifies the page into one "signal" language instead of adding a competing accent.

### Type — make Roboto work harder, add no font

Roboto 400/500 stays (PDF + body). Screen gets a **deliberate scale**, not a new face:

- **Hero**: larger, tighter display sizing of the existing name/title (already present) — the
  characteristic opening.
- **Section eyebrow**: a small uppercase, letter-spaced label above each rail section (e.g. the section
  name as a "route" label). Justified because it labels a real, ordered region.
- **Card title / period / badges**: existing treatment, tuned for the card's fixed footprint.

### Layout — vertical page, horizontal rails

The 002 vertical page + sticky section nav is kept. The three dense sections become rails:

```text
mobile (one focal card + peek)              desktop (same model, wider card + controls)
┌─────────────────────────┐                ┌───────────────────────────────────────────┐
│ [sticky section nav]     │                │ [sticky section nav]                        │
│                          │                │                                             │
│ EXPERIENCE  (eyebrow)    │                │ EXPERIENCE            (eyebrow)      ‹  ›    │  ← prev/next (JS)
│ ┌───────────────┐┌──    │  ← rail track  │ ┌─────────────────────────┐┌──────         │
│ │  focal card   ││ pe   │    (snap)      │ │      focal card         ││  peek…         │
│ │               ││ ek   │                │ │                         ││                │
│ └───────────────┘└──    │                │ └─────────────────────────┘└──────         │
│  ◦──◦──●──◦──◦           │  ← SIGNATURE   │  ◦──◦──●──◦──◦──◦──◦    3 / 7               │
│  route indicator         │    (route)     │  route indicator                            │
│                          │                │                                             │
│ (page keeps scrolling ↓) │                │ (page keeps scrolling ↓)                    │
└─────────────────────────┘                └───────────────────────────────────────────┘
```

- One focal card + a peek of the next at **every** breakpoint (no multi-card grid) — confirmed in
  clarify.
- The rail scrolls in its own track; the **page never scrolls horizontally**.
- Non-rail sections (header, About, Skills) are unchanged from 002.

## The signature: "route between nodes"

Below each rail, the position indicator is drawn as a **route**: one node per card, connected by a
line, the current card's node filled in `signal` red (a subtle, reduced-motion-aware pulse on change).
It reads as a dispatch route / a path across a distributed topology — the subject's domain.

Why this is a *choice*, not a default (frontend-design critique):

- **Content-true, not decorative**: a rail *is* an ordered sequence, so a position/route indicator
  encodes something real (which card, how many, there's-more) — passing the "does this marker actually
  belong?" test. Plain carousel dots would be the templated answer; framing them as a connected
  **route with a live node** ties them to the brief.
- **One bold thing, everything else quiet**: no new palette, no new font, no extra chrome — the route
  indicator is the single memorable element; the rest stays disciplined (Chanel's "remove one
  accessory").
- **Doubles as function**: it *is* the accessible position affordance + the `aria-live` target + the
  "there's more" cue the research calls for — decoration and utility are the same object.
- **Avoids the AI-default clusters**: not cream+serif+terracotta, not black+acid-green, not
  broadsheet-hairlines; the distinctiveness is structural (the routing metaphor), derived from the
  subject.

Screen-only: in `@media print` the route indicator and all rail chrome vanish; entries flatten to the
existing linear list (PDF unchanged).

## Quality floor (baked in, per frontend-design + the a11y research)

- Responsive down to ~320px; the page never scrolls horizontally.
- Visible keyboard focus; the rail is a focusable, labelled region; cards reachable in order.
- `prefers-reduced-motion` respected (instant snap, no glide/pulse).
- No layout shift from rails or the signature (CLS ≈ 0).
- Works with no JS (rail = scrollable strip; the route indicator degrades to the native scrollbar/peek
  as the "there's-more" cue).

## Deferred to implementation

Exact card dimensions/peek ratio per breakpoint, the eyebrow's precise treatment, the route
indicator's exact node styling and pulse timing, and whether prev/next controls are icon buttons or
the route nodes themselves are clickable — all decided during build against the visual gate, within
the tokens and contract above.
