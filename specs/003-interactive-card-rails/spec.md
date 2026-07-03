# Feature Specification: Digital CV — interactive swipeable card rails

**Feature Branch**: `003-interactive-card-rails`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Make the digital CV more interactive and engaging by presenting
content-dense sections as horizontally swipeable, accessible card rails, layered on the existing
responsive vertical page — without changing the PDF. Builds on the 002 redesign (card/section layout,
sticky section nav, scroll-reveal, screen/print CSS decoupling, and a visual-regression + PDF-render
test gate). Stay vanilla (HTML/CSS + light progressive-enhancement JS, CSS scroll-snap); no framework
migration; content unchanged; static, no backend; the PDF stays a clean linear document; accessible
and progressive-enhancement-safe; the existing test gate keeps guarding it."

## Clarifications

### Session 2026-07-03

- Q: Which sections become swipeable card rails? → A: The three content-dense, multi-entry sections —
  Professional Experience, Additional Experience, Robotics Competitions. Skills (bar grid, kept
  un-carded for PDF fidelity) and About (single card) stay as-is.
- Q: How should a rail advance between cards? → A: Snap-with-peek — free swipe/scroll that snaps to a
  card, always showing a peek of the next (native scroll-snap; the no-JS fallback is a plain scrollable
  strip). Not a strict one-card pager.
- Q: On wide desktop screens, how many cards should a rail show? → A: One focal card at a time with a
  peek of the next (same feel as mobile; the rail scrolls) — rails do not expand into a multi-card grid.
- Q: The distinctive "signature" moment — decide now or at design? → A: Defer the concrete form to
  `/speckit-plan` (with the frontend-design skill); the spec keeps it intent-level.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Swipe through content-dense sections as card rails (Priority: P1)

As a visitor (often a recruiter on a phone), I want the long, content-dense sections of the CV
(Professional Experience, Additional Experience, Robotics Competitions) presented as **horizontally
swipeable card rails** — where I flick/drag through entries one at a time with a peek of the next
card — so I can browse those sections quickly and engagingly instead of scrolling a long vertical
page.

**Why this priority**: This is the core user-facing improvement and the whole reason for the
initiative — turning long stacked sections into a compact, interactive, app-like browsing experience.
It delivers the headline value on its own.

**Independent Test**: Load the page on a phone, tablet, and desktop → each content-dense section is a
horizontal rail; the visitor can move through its cards (swipe on touch, and via pointer and keyboard
on desktop) with a peek of the adjacent card; the surrounding vertical page and the sticky section nav
still work; the page never scrolls horizontally as a whole; and the generated PDF is unchanged.

**Acceptance Scenarios**:

1. **Given** the digital page on a touch device, **When** the visitor swipes horizontally on a
   content-dense section, **Then** the section's cards move one at a time and settle (snap) on a card,
   showing a peek of the next.
2. **Given** the digital page on a desktop (no touch), **When** the visitor uses the on-screen
   controls, pointer, or keyboard, **Then** they can move through the same rail's cards, with a clear
   indication of position and more cards available.
3. **Given** any target breakpoint, **When** the page renders, **Then** the **page itself never
   scrolls horizontally** — only the rails scroll within their own track — and every card's content is
   reachable and legible.
4. **Given** the redesigned page, **When** the PDF is generated from the same build, **Then** the PDF
   is **unchanged** — the rails flatten to the existing clean, linear entries, with no interactive
   chrome, and the Download-PDF and QR cross-links intact.

---

### User Story 2 - Accessible and works without JavaScript (Priority: P2)

As a keyboard or screen-reader user — or any visitor whose JavaScript doesn't run, or who prefers
reduced motion — I want the card rails to be fully usable and to never hide content behind a gesture,
so the CV is complete and navigable for everyone.

**Why this priority**: Accessibility and graceful degradation are core quality bars for a public CV;
an interaction that only works for touch/mouse users, or that hides content when JS fails, is not
acceptable. It is separable from P1 (P1 delivers the interaction; P2 guarantees it's usable by all).

**Independent Test**: With a keyboard only, tab/arrow through a rail's cards with a visible focus
indicator; with a screen reader, the rail is announced as a list of cards; with JavaScript disabled,
each rail is still a horizontally scrollable container and **all** content is reachable; with "reduce
motion" enabled, no non-essential motion plays. In every case no content is trapped or hidden.

**Acceptance Scenarios**:

1. **Given** a keyboard-only visitor, **When** they navigate a rail, **Then** each card is reachable
   with a visible focus indicator and standard key interactions move between cards.
2. **Given** a screen-reader user, **When** they reach a rail, **Then** it is exposed as a labelled
   list of cards they can move through in order.
3. **Given** a visitor with JavaScript disabled (or before scripts run), **When** they view a
   content-dense section, **Then** it remains a horizontally scrollable strip and all cards/content are
   reachable — nothing is left hidden or requires a script to reveal.
4. **Given** a visitor who prefers reduced motion, **When** they interact with a rail, **Then**
   non-essential animation is disabled while the rail stays fully functional.

---

### User Story 3 - A distinctive signature moment & rail polish (Priority: P3)

As a visitor, I want the page to have one distinctive, memorable interactive moment and tasteful
polish on the rails (clear affordances, gentle emphasis of the focused card), so the CV feels
crafted and modern rather than generic — without distraction or hurting performance/accessibility.

**Why this priority**: A finishing enhancement layered on the P1 rails; it raises the impression from
"functional" to "memorable" but is not required for a usable, navigable interactive CV.

**Independent Test**: On screen, the signature moment is present and works across breakpoints and input
types, the rails show clear affordances (position/there's-more) and subtle focused-card emphasis, all
reduced-motion-aware and layout-shift-free; in the PDF, none of it appears.

**Acceptance Scenarios**:

1. **Given** a visitor with default settings, **When** they arrive and interact, **Then** one
   distinctive signature moment makes the page memorable while the rest stays disciplined.
2. **Given** any rail, **When** it is shown, **Then** affordances make it obvious that it is swipeable
   and how much more content there is (position indication + peek), with subtle emphasis on the
   focused card.
3. **Given** the reduced-motion preference or the PDF output, **When** the page/PDF renders, **Then**
   the signature/polish adds no motion (screen) and does not appear at all (PDF).

---

### Edge Cases

- **Single-card / short sections**: a section with only one entry shows no misleading "more" affordance
  and does not present an empty or broken rail.
- **Very long card content**: a single entry longer than the viewport stays fully readable (its own
  content scrolls or the card sizes to fit) without breaking the rail or overflowing the page.
- **Very small screens (~320px)**: rails and cards stay legible with the page never scrolling
  horizontally as a whole.
- **No JavaScript / progressive enhancement**: rails remain horizontally scrollable strips with all
  content reachable; the page is never left in a state that needs a script to show content.
- **Print / PDF isolation**: rail chrome (scroll tracks, controls, position indicators, the signature
  moment, animation) must not leak into the PDF, which stays a clean linear document.
- **Reduced-motion / accessibility**: swipe/scroll still works; non-essential motion is suppressed; the
  page stays keyboard-navigable with visible focus.
- **Content edits**: adding/removing an entry in the content file must not break a rail, its
  affordances, or the rendering checks.
- **Intentional vs. accidental visual change**: because the check is visual-regression, the rails'
  deterministic **resting state** is captured in the committed baselines; a deliberate change updates
  them (reviewed), while an unintended visual diff fails the check.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The digital (screen) CV MUST present the content-dense sections (Professional Experience,
  Additional Experience, Robotics Competitions) as **horizontally swipeable card rails** — one card
  advanced at a time, settling (snapping) on a card, with a **peek** of the adjacent card. This
  single-focal-card-with-peek presentation applies at **every breakpoint, including wide desktop** —
  rails do not expand into a multi-card grid.
- **FR-002**: Each rail MUST be operable by **touch (swipe/drag), pointer, and keyboard**, and MUST
  show its **position and that more cards exist** (e.g. peek + a position indicator/controls). On
  devices without touch, an equivalent non-touch way to advance MUST be available.
- **FR-003**: The **page itself MUST never scroll horizontally** at any target breakpoint — only the
  rails scroll within their own track — and every card and its content MUST remain reachable and
  legible.
- **FR-004**: The existing **vertical page structure and the sticky section navigation MUST be kept**;
  the sticky nav still jumps to each section, and non-rail sections (header, About, Skills) are
  unchanged.
- **FR-005**: The rails and all interactive chrome MUST be **screen-only**; in print/PDF they flatten
  to the existing **clean, linear entries** (extending the 002 screen/print decoupling). The **PDF MUST
  remain unchanged** in content, order, and form, and its generation MUST NOT be complicated (no change
  to the PDF renderer).
- **FR-006**: The CV MUST remain **usable with no JavaScript** — each rail degrades to a horizontally
  scrollable strip with **all content reachable**; content MUST NEVER be hidden behind a gesture or
  require a script to be revealed (progressive enhancement).
- **FR-007**: The rails MUST be **accessible** — keyboard-navigable with a visible focus indicator,
  exposed to assistive tech as a labelled list of cards, sufficient contrast, and respectful of the
  **reduced-motion** preference.
- **FR-008**: The page MUST include **one distinctive "signature" interactive moment** that makes it
  memorable, while the rest of the interface stays disciplined; its concrete form is chosen at design
  time.
- **FR-009**: Motion (snap feedback, focused-card emphasis, the signature moment) MUST be **subtle,
  reduced-motion-aware, and cause no layout shift**.
- **FR-010**: CV **content is unchanged** — it remains sourced from the existing content data file;
  this feature changes presentation and interaction, not content.
- **FR-011**: The site MUST remain a **static build** with **no backend, database, or API**; any
  interactivity is client-side only, and it stays on the **existing template engine (no framework
  migration)**.
- **FR-012**: The existing automated **visual-regression + PDF-render gate MUST keep guarding the
  page**: the rails' deterministic resting state is captured in the committed baselines, the PDF check
  stays green, and the checks remain runnable locally with the same result as CI. Local development, the
  build pipeline, and the deploy flow MUST remain intact.

### Key Entities *(include if feature involves data)*

- **Content sections & entries**: the existing content groups from the content data file — the
  content-dense ones (`positions`, `experience`, `competitions`) provide the **entries** that become
  the **cards** within each section's **rail**; header, About, and Skills are unchanged. No new content,
  fields, or data source is introduced (this is a presentation/interaction model over the 002 model).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a phone, a visitor can move through the entries of a content-dense section by swiping,
  reaching any entry in that section in **under ~5 seconds**, without scrolling the whole page.
- **SC-002**: Across **all target breakpoints (xs/sm/md/lg/xl/xxl)** the **page never scrolls
  horizontally**, every rail's cards are reachable, and every major section stays visible and legible
  (verified by the visual-regression check).
- **SC-003**: With **JavaScript disabled**, **100%** of the CV content remains reachable and readable
  (no card or entry is hidden or requires a script to reveal).
- **SC-004**: The generated **PDF is unchanged** by this feature — same sections and entries in the
  same linear order, no interactive/rail chrome, Download-PDF and QR cross-links intact.
- **SC-005**: The rails are **fully keyboard-operable** (every card reachable with visible focus) and
  expose their cards to assistive tech as a navigable list; reduced-motion users get no non-essential
  motion.
- **SC-006**: A responsive regression (page horizontal overflow, a hidden/broken rail), an unintended
  visual change, or a PDF-render failure is caught by the gate **100% of the time** and blocks the PR.
- **SC-007**: The site still deploys as a **static** artifact (no backend/DB/API), on the existing
  build/deploy flow, and contributors can reproduce the CI rendering result locally.
- **SC-008**: Interacting with a rail causes **no visible layout shift**, and the page's main content
  is visible on a typical mobile connection in **under ~2.5 seconds**.

## Assumptions

- **Which sections become rails** (confirmed): the three content-dense, multi-entry sections —
  Professional Experience, Additional Experience, Robotics Competitions. Header, About (single card),
  and Skills (bar grid, kept un-carded for PDF fidelity) are **not** rails.
- **Rail behavior** (confirmed): free horizontal swipe/scroll that **snaps** to cards with a peek of
  the next (native scroll-snap), not a strict one-card-per-action pager; one focal card with a peek at
  every breakpoint (no multi-card grid on desktop). Desktop gets an equivalent non-touch affordance.
- **Signature moment**: intentionally left to design (`/speckit-plan`, using the frontend-design
  skill); a seed idea is a "distributed-systems / routing-between-nodes" motif that fits the subject,
  but the spec only requires *one distinctive, accessible, screen-only signature*.
- **Foundation reused**: the 002 screen/print CSS decoupling, sticky section nav, vendored fonts, and
  the visual-regression + PDF-render gate are the base; this feature extends them (e.g. new baselines
  for the rails' resting state) rather than replacing them.
- **Vanilla + progressive enhancement**: implemented with HTML/CSS + light client-side JavaScript
  (CSS scroll-snap for the rails); the existing template engine is retained; no framework, no backend.
- **Primary audience**: a recruiter on a phone for the digital experience; the PDF serves formal/
  offline sharing and is deliberately kept identical.
