# Data model: interactive card rails

No new data source or schema — CV content stays in `src/metadata/metadata.js` (unchanged, FR-010).
This records how the **existing** content (already modelled for 002) maps to the rail presentation. It
is a presentation model, not a persistence model.

## Sections → rails (from `metadata.js`)

| Section | Source key | Screen (002 → 003) | Print |
|---------|-----------|--------------------|-------|
| Header / identity | `name`, `title`, `facts`, photo | Hero (unchanged) + Download-PDF | identity + QR |
| About | `about_me` | Intro card (unchanged) | linear paragraph |
| Skills | `skills` | Bar grid (unchanged, un-carded) | linear list/bars |
| **Professional experience** | `positions[]` | **Rail** of position cards | linear entries (`break-inside: avoid`) |
| **Additional experience** | `experience[]` | **Rail** of entry cards | linear entries |
| **Robotics competitions** | `competitions[]` | **Rail** of entry cards | linear entries |

Only the three multi-entry, content-dense sections become rails (confirmed in clarify). Header, About,
and Skills are unchanged from 002. An entry's existing shape is reused unchanged: `title`, `period`,
`contents` (Markdown), `skills[]` (badges; omitted for competitions).

## Derived presentation entities (screen-only)

- **Rail**: a section's ordered set of entries presented as a horizontally scroll-snapping track. A
  rail exists only for a non-empty dense section; a section with one entry renders as a single card
  with **no** "more" affordance (edge case). Exposed as a labelled, focusable scrollable region
  wrapping a `<ul>` of cards.
- **Card**: one entry, the focal unit of a rail (one focal card + peek of the next at every
  breakpoint). Same content as the 002 card; its interactive links remain the natural focus targets.
- **Route node**: one marker per card in the rail's **route indicator** (the signature). Ordered;
  exactly one is "active" (the snapped card), rendered in the `signal` accent. Derived from the card
  count + current scroll position — no new data.

## Invariants

- **Content parity**: screen and PDF present the *same* entries in the same order; only presentation
  (rail vs. linear, chrome, signature) differs (FR-005, SC-004).
- **No content added**: no new fields, entities, or data source; the route nodes are derived from the
  existing entry count/order (FR-010).
- **Reachability**: every card/entry is reachable without JavaScript (a scrollable strip) and by
  keyboard (SC-003, FR-006/FR-007) — nothing is derived state that hides content.
- **Empty/'single' safety**: a removed or single entry must not leave a dangling rail, a broken route
  indicator, or a misleading affordance.
