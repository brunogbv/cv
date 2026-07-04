# Feature Specification: Digital CV — interactive editorial deck (full-viewport sections, summary-card rails, detail overlays)

**Feature Branch**: `003-respec` (feature dir: `specs/003-interactive-card-rails/`)

**Created**: 2026-07-03 (re-spec 2026-07-04)

**Status**: Draft (re-spec — supersedes the original "card rails" direction)

**Input**: User description: "Make the digital CV more interactive and engaging. After prototyping,
the validated direction (branch `003-proto`, owner-confirmed 'works perfectly') is an **editorial,
full-viewport section 'deck'**: each section fills the screen and a single scroll / swipe / key press
moves to the next, always resting centred on a section. The content-dense sections become horizontal
rails of **short summary cards** that open into a **full-screen detail overlay** on tap (no long
in-card scrolling). The screen adopts an **editorial restyle** (reference: theopenengine.com — a
display serif + a body sans, a warm cream/ink/slate/terracotta palette, no boxy cards), with skills
shown as compact proficiency chips. All of this is **screen-only**: the PDF stays a clean, linear,
unchanged document. Stay vanilla (HTML/CSS + light progressive-enhancement JS); no framework
migration; content unchanged; static, no backend; accessible and progressive-enhancement-safe; the
existing visual-regression + PDF-render gate keeps guarding it."

> **Re-spec note.** This feature was originally spec'd as "horizontally swipeable card rails" layered on
> the existing vertical page. A throwaway prototype (`003-proto`) validated a materially different
> design — a full-viewport vertical **deck** with **native CSS Scroll Snap**, summary cards that open a
> **full-screen detail overlay**, and an **editorial restyle**. The owner rejected the original UX and
> confirmed the new one. This document re-specs feature 003 to the validated direction; the horizontal
> "rails" survive as **one component** (the content-dense sections), not the headline. The original
> rails task issues and the superseded rails implementation (PR #155) are closed as superseded.

## Clarifications

### Session 2026-07-04 (re-spec)

- Q: What is the primary screen interaction model? → A: A **full-viewport vertical "deck"** — each
  section is ~one viewport tall with vertically-centred content; one scroll/swipe/key press advances
  exactly one section and it rests centred. Implemented with **native CSS Scroll Snap**
  (`scroll-snap-type: y mandatory` + `scroll-snap-align: start` + `scroll-snap-stop: always`), **not** a
  hand-rolled JS scroll-jacker (which fights native trackpad momentum — see
  `docs/interaction-gotchas.md`). Keyboard section nav is a thin JS layer (`scrollIntoView`) that
  coexists with snap.
- Q: How do content-dense entries present their detail? → A: The rail shows **short summary cards**
  (period, title, teaser); activating a card opens its **full detail in a full-screen overlay** (a
  focused card on a dimmed/blurred backdrop), closeable by Escape, a close control, or clicking/tapping
  outside. No long in-card scrolling. The overlay is `:target`-based so it works with **no JS**.
- Q: What visual style? → A: An **editorial restyle** referencing theopenengine.com — a display serif
  for headings + a body sans, a warm cream/ink/slate/terracotta palette, no boxy cards, small uppercase
  "eyebrow" labels above section titles. **Screen-only**; the PDF keeps its existing Roboto/linear form.
- Q: How are Skills shown? → A: Compact **proficiency chips** — one chip per skill, visually filled to
  its proficiency percentage — so the section fits one deck panel (replacing the 002 bar grid on screen).
- Q: Are fonts loaded from a CDN? → A: **No.** The prototype used a CDN for speed; production MUST
  **vendor** the display + body fonts (self-hosted, screen-only) so there is no third-party request at
  render time (consistent with the existing vendored Roboto/Bootstrap/Font Awesome).
- Q: Does the full-viewport deck apply on small phones, or relax there? → A: **Deck everywhere, relax
  tall panels** — the deck + snap apply at all breakpoints, but any section whose content exceeds the
  viewport (mainly small phones) relaxes to internal scroll (mandatory snap only for panels that fit),
  so content is never trapped. Keeps the deck feel for the phone-first audience.
- Q: How should the deck behave under `prefers-reduced-motion`? → A: **Keep snap, drop the glide** —
  sections still snap to rest (a resting position, not animation), but the smooth animated glide and
  overlay/emphasis transitions are suppressed (movement is immediate).

### Session 2026-07-03 (carried over, still valid)

- Q: Which sections become swipeable rails? → A: The three content-dense, multi-entry sections —
  Professional Experience, Additional Experience, Robotics Competitions. About (single card) and Skills
  (now chips) are not rails.
- Q: How should a rail advance between cards? → A: Snap-with-peek — free horizontal swipe/scroll that
  snaps to a card, always showing a peek of the next (native scroll-snap; the no-JS fallback is a plain
  scrollable strip). Not a strict one-card pager.
- Q: The distinctive "signature" moment — decide now or at design? → A: Defer the concrete form to
  `/speckit-plan` (with the frontend-design skill); the spec keeps it intent-level.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse the CV as a full-viewport section deck (Priority: P1)

As a visitor (often a recruiter on a phone or a trackpad laptop), I want to move through the CV **one
full-screen section at a time** — a calm, app-like "deck" where each section fills the viewport and a
single scroll, swipe, or arrow-key press advances to the next and rests centred on it — so browsing
feels deliberate and modern instead of an endless scroll.

**Why this priority**: This is the headline "more interactive" transformation and the reason for the
re-spec. It is the interaction skeleton the rest hangs on and delivers the core value on its own.

**Independent Test**: On desktop (mouse wheel, macOS trackpad, and Arrow/Page keys) and on touch, each
gesture/press advances **exactly one section** and the page comes to rest **centred on a section, never
between two**; the sticky section nav still jumps to any section; the page never scrolls horizontally;
and the generated PDF is unchanged.

**Acceptance Scenarios**:

1. **Given** the digital page on a trackpad laptop, **When** the visitor does a soft two-finger scroll
   or a hard flick, **Then** the deck advances one section and settles centred — it never lands or
   flickers between sections (a hard flick still advances only one).
2. **Given** the page on any device, **When** the visitor presses ArrowDown/ArrowUp (or PageDown/Up),
   **Then** exactly one section is traversed per press and it lands centred.
3. **Given** the page, **When** the visitor uses the sticky section nav, **Then** it moves to and rests
   centred on the chosen section (same landing as a gesture).
4. **Given** a visitor who prefers reduced motion, **When** they navigate the deck, **Then** movement is
   immediate (no smooth glide) while still resting one section at a time.

---

### User Story 2 - Skim content-dense sections as summary-card rails with detail on demand (Priority: P2)

As a visitor, I want the long, content-dense sections (Professional Experience, Additional Experience,
Robotics Competitions) shown as **horizontal rails of short summary cards** that I can swipe through,
and I want to **tap a card to see its full details full-screen** — so I can scan a section quickly and
drill into any entry on demand, without scrolling a long card or a long page.

**Why this priority**: It is the content-dense browsing model — the main way the CV's substance is
explored — layered on the P1 deck. High value, but the deck is shippable without it.

**Independent Test**: Each of the three sections is a horizontal rail of summary cards with a peek of
the next; activating a card opens its full content in a full-screen overlay; closing returns to the
section, still centred; the page never scrolls horizontally; with JavaScript disabled the detail is
still reachable and all content readable; and the PDF shows the full entries in a clean linear order.

**Acceptance Scenarios**:

1. **Given** a content-dense section in the deck, **When** the visitor swipes/scrolls the rail
   horizontally, **Then** cards move and settle with a peek of the next, and the **page does not scroll
   horizontally as a whole**.
2. **Given** a summary card, **When** the visitor taps/clicks or activates it by keyboard, **Then** its
   **full detail opens in a full-screen overlay** (a focused card on a dimmed/blurred backdrop).
3. **Given** an open detail overlay, **When** the visitor presses Escape, activates the close control,
   or clicks/taps outside the card, **Then** the overlay closes and the section is shown centred as
   before, and the page behind it did not scroll while the overlay was open.
4. **Given** JavaScript is disabled, **When** the visitor activates a summary card, **Then** its full
   detail is still revealed (e.g. the overlay shows via a URL-fragment target) and can be dismissed —
   no content is trapped behind a script.

---

### User Story 3 - Editorial reference restyle (Priority: P2)

As a visitor, I want the digital CV to have a distinctive, editorial visual identity — a display serif
for headings, a clean body sans, a warm cream/ink/terracotta palette, generous type, small uppercase
"eyebrow" labels, and skills shown as compact proficiency chips — so it reads as a crafted personal
site rather than a generic template, **while the PDF keeps its established clean, linear form**.

**Why this priority**: The visual identity is central to the CV's impression and was a core part of
what the owner validated. It is separable from the interaction (the deck/rails work regardless of
skin), so it is its own story rather than a blocker for P1.

**Independent Test**: On screen, headings render in the display serif and body in the sans (both
**vendored**, no third-party font request at render time), the palette/eyebrows/"no boxy cards"
editorial layout is applied across all breakpoints, and Skills render as proficiency-filled chips; in
the PDF, none of the restyle appears — it stays Roboto and linear.

**Acceptance Scenarios**:

1. **Given** the digital page, **When** it renders, **Then** headings use the display serif and body
   text the body sans, both **self-hosted/vendored** (no CDN/third-party request at render time).
2. **Given** the digital page, **When** it renders, **Then** the editorial palette, uppercase eyebrow
   labels, and un-boxed layout are applied, and Skills appear as compact chips filled to each skill's
   proficiency.
3. **Given** the same build, **When** the PDF is generated, **Then** it is **unchanged** — Roboto, the
   existing linear layout, no editorial restyle, chips, or screen palette.

---

### User Story 4 - Accessible, works without JavaScript, reduced-motion safe (Priority: P2)

As a keyboard or screen-reader user — or any visitor whose JavaScript doesn't run, or who prefers
reduced motion — I want the deck, the rails, and the detail overlays to be fully usable and to never
hide content behind a gesture, so the CV is complete and navigable for everyone.

**Why this priority**: Accessibility and graceful degradation are non-negotiable quality bars for a
public CV. Separable from the interaction stories (which deliver the behaviour) — this guarantees it is
usable by all.

**Independent Test**: Keyboard-only, traverse the whole deck and every rail, open and close a detail
overlay with focus trapped in the overlay and returned to the triggering card on close; a screen reader
announces sections as regions, rails as labelled lists of cards, and the detail as a dialog; with
JavaScript disabled all content (including every detail) is reachable via native scroll/snap and
URL-fragment targets; with reduced-motion enabled no non-essential animation plays. In every case no
content is trapped or hidden.

**Acceptance Scenarios**:

1. **Given** a keyboard-only visitor, **When** they navigate, **Then** the deck advances by section
   keys, each rail's cards are reachable with a visible focus indicator, a card opens its detail, and
   focus moves into the overlay and returns to the card on close.
2. **Given** a screen-reader user, **When** they traverse the page, **Then** sections are exposed as
   labelled regions, each rail as a labelled list of cards, and an open detail as a dialog.
3. **Given** JavaScript disabled (or before scripts run), **When** the visitor views any section,
   **Then** native scroll snapping still rests on sections, rails remain scrollable strips, details are
   still openable/closeable via URL-fragment targets, and **100%** of content is reachable.
4. **Given** a visitor who prefers reduced motion, **When** they interact, **Then** smooth glides and
   non-essential animation are suppressed while the deck, rails, and overlays stay fully functional.

---

### User Story 5 - A distinctive signature moment & polish (Priority: P3)

As a visitor, I want the page to have one distinctive, memorable interactive moment and tasteful polish
(clear rail affordances, gentle emphasis of the focused card/section), so the CV feels crafted — without
distraction or hurting performance/accessibility.

**Why this priority**: A finishing enhancement layered on the interaction and restyle; it raises the
impression from "polished" to "memorable" but is not required for a usable, navigable, well-styled CV.

**Independent Test**: On screen the signature moment is present and works across breakpoints and input
types, rails show clear affordances (peek + position/there's-more) and subtle focused-card emphasis, all
reduced-motion-aware and layout-shift-free; in the PDF, none of it appears.

**Acceptance Scenarios**:

1. **Given** a visitor with default settings, **When** they arrive and interact, **Then** one
   distinctive signature moment makes the page memorable while the rest stays disciplined.
2. **Given** any rail, **When** it is shown, **Then** affordances make it obvious the rail is swipeable
   and how much more content exists (peek + position indication), with subtle focused-card emphasis.
3. **Given** the reduced-motion preference or the PDF output, **When** the page/PDF renders, **Then**
   the signature/polish adds no motion (screen) and does not appear at all (PDF).

---

### Edge Cases

- **Deck rest state**: after any wheel/trackpad/touch gesture the page must come to rest on a section,
  never stranded between two (native snap, `scroll-snap-stop: always`), and a hard flick advances only
  one section.
- **Section taller than the viewport**: if a section's content can exceed the viewport at a breakpoint,
  it must stay fully readable (that section scrolls internally / relaxes snapping) without the deck
  trapping content — mandatory snap is reserved for uniform ~viewport-height panels.
- **Nested scrolling (rail inside a deck panel)**: swiping a horizontal rail must not fight or trigger
  the vertical deck snap, and reaching a rail end must not chain-scroll the deck unexpectedly.
- **Detail overlay & background**: while a detail overlay is open, the page behind it must not scroll;
  closing must return to the section centred; opening/closing must not jump the section off-centre.
- **Single-card / short sections**: a section with one entry shows no misleading "more" affordance and
  no empty/broken rail.
- **Very small screens (~320px) & the deck on mobile**: sections, rails, and overlays stay legible; the
  page never scrolls horizontally; the full-viewport deck remains comfortable (content fits or the
  section relaxes to normal scroll rather than clipping).
- **No JavaScript / progressive enhancement**: the deck still snaps (pure CSS), rails stay scrollable
  strips, detail overlays open/close via URL-fragment targets, and all content is reachable; nothing
  requires a script to be revealed.
- **Print / PDF isolation**: the deck, rails, overlays, editorial restyle, chips, signature, and all
  animation are screen-only and must not leak into the PDF, which stays a clean linear Roboto document.
- **Reduced-motion / accessibility**: gestures still work; smooth glides and non-essential motion are
  suppressed; the page stays keyboard-navigable with visible focus and correct overlay focus handling.
- **Content edits**: adding/removing an entry in the content file must not break a rail, a deck panel,
  an overlay, its affordances, or the rendering checks.
- **Intentional vs. accidental visual change**: because the check is visual-regression, the deterministic
  **resting state** (deck at rest, rails at rest, an overlay closed) is captured in committed baselines;
  a deliberate change updates them (reviewed), while an unintended visual diff fails the check.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The digital (screen) CV MUST present its sections as a **full-viewport vertical "deck"** —
  each section ~one viewport tall with vertically-centred content — where one wheel/trackpad/touch
  gesture or one Arrow/Page keypress advances **exactly one section** and the page **rests centred on a
  section, never between two**. The deck applies at **all breakpoints**; however, a section whose content
  **exceeds the viewport** (chiefly on small phones) MUST relax so that section scrolls internally and is
  never clipped or trapped — mandatory snapping is reserved for panels that fit the viewport.
- **FR-002**: Deck scrolling MUST be driven by **native CSS Scroll Snap** (`scroll-snap-type: y
  mandatory`, `scroll-snap-align`, `scroll-snap-stop: always`) so the browser owns wheel/trackpad/touch
  momentum. The implementation MUST NOT hand-roll a wheel/touch scroll-jacker (per
  `docs/interaction-gotchas.md`). Keyboard section navigation MAY be a thin JS enhancement
  (`scrollIntoView`) that coexists with snap; it MUST NOT intercept wheel/touch.
- **FR-003**: The content-dense sections (Professional Experience, Additional Experience, Robotics
  Competitions) MUST be **horizontal rails of short summary cards** (period, title, teaser) with a
  **peek** of the adjacent card, at every breakpoint (no multi-card grid on desktop). Activating a
  summary card MUST open its **full detail in a full-screen overlay** (a focused card on a
  dimmed/blurred backdrop). Long content MUST NOT require scrolling within a summary card.
- **FR-004**: A detail overlay MUST be dismissible by **an explicit close control, clicking/tapping
  outside the card, and (as a JavaScript enhancement) the Escape key**; on close the underlying section
  MUST be shown **centred** as before. While an overlay is open, the page behind it MUST NOT scroll.
- **FR-005**: The detail overlay MUST work with **no JavaScript** — it opens and closes via a
  **URL-fragment target** (the summary card, the close control, and the outside-click backdrop are all
  fragment links), so the full content is reachable and dismissible without scripts. (Escape-to-close
  is a JS-only enhancement layered on top; the fragment-based paths are the no-JS guarantee.)
- **FR-006**: The **page itself MUST never scroll horizontally** at any target breakpoint — only rails
  scroll within their own track — and swiping a rail MUST NOT fight or mis-trigger the vertical deck
  snap, nor chain-scroll the deck at a rail's end.
- **FR-007**: The screen MUST adopt the **editorial restyle**: a **display serif** for headings and a
  **body sans** for text, a warm cream/ink/slate/terracotta palette, an un-boxed editorial layout, and
  small uppercase "eyebrow" labels above section titles. Skills MUST render as **compact chips filled to
  each skill's proficiency**. All of this is **screen-only**.
- **FR-008**: The display and body fonts MUST be **vendored/self-hosted** (no CDN or third-party font
  request at render time), consistent with the existing vendored assets; they are applied **screen-only**
  so the PDF keeps Roboto.
- **FR-009**: The deck, rails, overlays, restyle, chips, signature, and all interactive chrome MUST be
  **screen-only**; in print/PDF they flatten to the existing **clean, linear entries** (extending the
  002 screen/print decoupling). The **PDF MUST remain unchanged** in content, order, typography (Roboto),
  and form, and its generation MUST NOT be complicated (no change to the PDF renderer).
- **FR-010**: The existing **vertical page structure and sticky section navigation MUST be kept**; the
  sticky nav still jumps to (and rests centred on) each section.
- **FR-011**: The CV MUST remain **usable with no JavaScript** — the deck still snaps (pure CSS), rails
  degrade to horizontally scrollable strips, detail overlays open/close via fragment targets, and **all
  content is reachable**; content MUST NEVER be hidden behind a gesture or require a script to be
  revealed.
- **FR-012**: The interaction MUST be **accessible** — the deck and rails keyboard-navigable with a
  visible focus indicator; sections exposed as labelled regions, rails as labelled lists of cards, and an
  open detail as a dialog with **focus moved into it and returned to the triggering card on close**;
  sufficient contrast; and respectful of the **reduced-motion** preference.
- **FR-013**: The page MUST include **one distinctive "signature" interactive moment** that makes it
  memorable while the rest stays disciplined; its concrete form is chosen at design time.
- **FR-014**: Motion (deck glide, snap feedback, focused-card emphasis, overlay transition, the signature
  moment) MUST be **subtle, reduced-motion-aware, and cause no layout shift**. Under
  `prefers-reduced-motion`, section **snapping is retained** (it is a resting position, not animation)
  while the smooth glide and overlay/emphasis transitions are **suppressed** (movement is immediate).
- **FR-015**: CV **content is unchanged** — it remains sourced from the existing content data file; this
  feature changes presentation and interaction, not content.
- **FR-016**: The site MUST remain a **static build** with **no backend, database, or API**; any
  interactivity is client-side only, on the **existing template engine (no framework migration)**.
- **FR-017**: The existing automated **visual-regression + PDF-render gate MUST keep guarding the page**:
  the deterministic resting states (deck at rest, rails at rest, overlay closed) are captured in the
  committed baselines, the **PDF visual check** stays green, and the checks remain runnable locally with
  the same result as CI. Local development, the build pipeline, and the deploy flow MUST remain intact.

### Key Entities *(include if feature involves data)*

- **Content sections & entries**: the existing content groups from the content data file. The
  content-dense ones (`positions`, `experience`, `competitions`) provide the **entries** that become the
  **summary cards** (and their **detail overlays**) within each section's **rail**. `about_me` is a
  single panel; `skills` render as proficiency chips. No new content, fields, or data source is
  introduced — this is a presentation/interaction model over the existing 002 content model.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On desktop (wheel, trackpad, Arrow/Page keys) and on touch, a gesture/press advances
  **exactly one section** and the page comes to rest **on a section (never between two)** — verified
  including a hard trackpad flick (advances only one).
- **SC-002**: On a phone, a visitor can reach any entry of a content-dense section by swiping its rail
  and open that entry's full detail in **≤ 2 interactions**, without scrolling the whole page.
- **SC-003**: Across **all target breakpoints (xs/sm/md/lg/xl/xxl)** the **page never scrolls
  horizontally**, every deck section and rail card is reachable, and every section stays legible
  (verified by the visual-regression check).
- **SC-004**: With **JavaScript disabled**, **100%** of the CV content remains reachable and readable —
  the deck still snaps, rails scroll, and every detail overlay can be opened and dismissed via
  URL-fragment targets; nothing is hidden or requires a script.
- **SC-005**: The generated **PDF is unchanged** by this feature — same sections and entries in the same
  linear order, Roboto typography, no deck/rail/overlay/restyle chrome, Download-PDF and QR cross-links
  intact (verified by the PDF visual check).
- **SC-006**: The interaction is **fully keyboard-operable** (deck, every rail card reachable with
  visible focus, detail open/close with focus trapped then returned) and exposes sections/rails/overlay
  to assistive tech as region/list/dialog; reduced-motion users get no non-essential motion.
- **SC-007**: A regression (page horizontal overflow, a stranded/between-sections rest state, a
  hidden/broken rail or overlay), an unintended visual change, or a PDF-render change is caught by the
  gate **100% of the time** and blocks the PR.
- **SC-008**: The site still deploys as a **static** artifact (no backend/DB/API) on the existing
  build/deploy flow, contributors reproduce the CI rendering result locally, and the display/body fonts
  incur **no third-party/CDN request at render time** (vendored).
- **SC-009**: Interacting with the deck, a rail, or an overlay causes **no visible layout shift**, and
  the page's main content is visible on a typical mobile connection in **under ~2.5 seconds**.

## Assumptions

- **Validated by prototype**: the design here is what branch `003-proto` validated and the owner
  confirmed ("works perfectly", 2026-07-04): editorial restyle + full-viewport deck (native scroll-snap)
  + summary-card rails with full-screen `:target` detail overlays + skills-as-proficiency-chips. The
  prototype is throwaway (CDN fonts, light a11y); production hardens it.
- **Scroll mechanism** (settled): **native CSS Scroll Snap**, not a JS scroll-jacker — the prototype
  proved a hand-rolled wheel/touch jacker fights native trackpad momentum (sluggish/flickering). See
  `docs/interaction-gotchas.md`. Keyboard nav is a thin `scrollIntoView` layer.
- **Which sections are rails** (confirmed): the three content-dense, multi-entry sections. About is a
  single panel; Skills are chips; neither is a rail.
- **Rail + detail behaviour** (confirmed): free horizontal swipe/scroll that snaps with a peek; summary
  cards are short; full detail opens in a full-screen overlay (dimmed/blurred backdrop), closeable by
  Esc / close control / outside click, `:target`-based for no-JS.
- **Fonts**: vendored/self-hosted (no CDN at render time), screen-only, so the PDF keeps Roboto — the
  concrete display serif + body sans (prototype used Fraunces + Spline Sans) are confirmed at design/plan.
- **Signature moment**: intentionally left to design (`/speckit-plan`, with the frontend-design skill);
  the spec only requires one distinctive, accessible, screen-only signature.
- **Foundation reused**: the 002 screen/print CSS decoupling, sticky section nav, vendored-asset
  pipeline, and the visual-regression + **PDF visual** gate (added in the harness work, #164) are the
  base; this feature extends them (new baselines for the deck/rail/overlay resting states) rather than
  replacing them.
- **Vanilla + progressive enhancement**: HTML/CSS + light client-side JS (native scroll-snap for the
  deck/rails, `:target` for overlays, a thin keyboard layer); existing template engine retained; no
  framework, no backend.
- **Primary audience**: a recruiter on a phone or trackpad laptop for the digital experience; the PDF
  serves formal/offline sharing and is deliberately kept identical.
