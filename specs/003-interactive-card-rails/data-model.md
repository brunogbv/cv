# Data model: interactive editorial deck

No new data source or schema — CV content stays in `src/metadata/metadata.js` (unchanged, FR-015).
This records how the **existing** content (already modelled for 002) maps to the deck presentation. It
is a presentation model, not a persistence model.

## Sections → deck panels (from `metadata.js`)

| Section | Source key | Screen (003 deck) | Print (PDF, unchanged) |
|---------|-----------|-------------------|------------------------|
| Header / identity | `name`, `title`, `facts`, photo | Hero panel (full-viewport) + Download-PDF | identity + QR |
| About | `about_me` | Panel — intro prose | linear paragraph |
| Skills | `skills` | Panel — **proficiency chips** | linear list/bars |
| **Professional experience** | `positions[]` | Panel — **summary-card rail** → detail overlay | linear entries (`break-inside: avoid`) |
| **Additional experience** | `experience[]` | Panel — **summary-card rail** | linear entries |
| **Robotics competitions** | `competitions[]` | Panel — **summary-card rail** | linear entries |

Every section is a full-viewport **deck panel** (D1/D2). Only the three multi-entry, content-dense
sections become rails (confirmed in clarify). An entry's existing shape is reused unchanged: `title`,
`period`, `contents` (Markdown), `skills[]` (badges; omitted for competitions).

## Derived presentation entities (screen-only)

- **Deck panel**: a section rendered ~one viewport tall with vertically-centred content, a
  `scroll-snap-align: start` snap target in the `y mandatory` deck. Relaxes to internal scroll if its
  content exceeds the viewport (D2).
- **Rail**: a dense section's ordered entries as a horizontally scroll-snapping track (`x mandatory`,
  peek of the next, `overscroll-behavior: contain`). Exists only for a non-empty dense section; a
  single-entry section renders one card with **no** "more" affordance (edge case). Exposed as a
  labelled list (`<ul>` of cards).
- **Summary card**: one entry's compact form (period, title, teaser) — the focal unit of a rail (one
  focal card + peek at every breakpoint). It is the **activator** (`<a href="#pN">`) that opens the
  entry's detail overlay.
- **Detail overlay**: one entry's **full** content (period, title, full `contents`, skill badges) shown
  full-screen on a dimmed/blurred backdrop. Keyed to the entry via `id="pN"` + `:target`; one open at a
  time; `role="dialog"` when JS present. Close links target `#experience` (the section).
- **Skill chip**: one `skills` entry rendered as a chip filled to its proficiency % (`--pct`). Derived
  from the existing `[name, percent]` skill shape — no new data.
- **Through-Line node**: one marker per **section** in the signature/progress spine (D8). Ordered;
  exactly one `aria-current` (the snapped section). Each node is an anchor to its section id. Derived
  from the existing section list + scroll position — no new data.

## Invariants

- **Content parity**: screen and PDF present the *same* entries in the same order; only presentation
  (deck/rail/overlay/chips/signature vs. linear Roboto) differs (FR-009, SC-005).
- **No content added**: no new fields, entities, or data source; chips, nodes, and overlays are derived
  from the existing entry/skill/section data (FR-015).
- **Reachability**: every entry (summary + full detail), chip, and section is reachable without
  JavaScript (native snap + scrollable rails + `:target` overlays) and by keyboard (SC-004, FR-011/12).
- **Summary ⇄ detail identity**: each summary card and its detail overlay describe the *same* entry;
  the detail carries the full `contents` the summary teases.
- **Empty/single safety**: a removed or single entry must not leave a dangling rail, a broken
  Through-Line node, an orphan overlay, or a misleading "more" affordance.
