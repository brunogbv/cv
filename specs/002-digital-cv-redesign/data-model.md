# Data model: Digital CV redesign

No new data source or schema — CV content stays in `src/metadata/metadata.js` (unchanged, FR-009).
This file records how that **existing** content maps to the redesign's presentation structure
(sections, navigation entries, cards). It is a presentation model, not a persistence model.

## Content sections (from `metadata.js`)

The existing top-level content groups become the page's **sections** — each a navigation target and a
titled block; their items render as **cards** on screen and flatten to linear blocks in print.

| Section | Source key(s) in `metadata.js` | Screen presentation | Print presentation |
|---------|-------------------------------|---------------------|--------------------|
| Header / identity | `name`, `title`, `facts`, photo | Hero block; facts as inline items; **Download-PDF** button (screen-only) | Same identity block; **QR** to the page (print-only) |
| About | `about_me` (Markdown) | Intro card | Linear paragraph |
| Skills | `skills` (`[label, percent]`) | Skill cards / bars | Linear list/bars |
| Professional experience | `positions[]` | One card per position | Linear entries (`break-inside: avoid`) |
| Additional experience | `experience[]` | One card per entry | Linear entries |
| Competitions | `competitions[]` | One card per entry | Linear entries |

Experience-style entries keep their existing shape: `title`, `period`, `contents` (Markdown),
`skills[]` (badges; omitted for competitions).

## Derived: section navigation

- Each section gets a stable **`id`** (e.g. `about`, `skills`, `experience`) used by the sticky nav's
  anchor links and `scroll-margin-top`.
- The **navigation list** is derived from the sections that are present/non-empty — a section with no
  content is neither rendered nor listed (edge case: content edits must not leave a dangling nav
  entry).

## Invariants

- **Content parity**: screen and PDF present the *same* content in the same order; only presentation
  (chrome, cards, animation, nav) differs (FR-005, SC-004).
- **No content added**: the redesign introduces no new fields, entities, or data source (FR-009).
- **Cross-links**: the screen Download-PDF control and the print QR both resolve (FR-006).
