# Feature Specification: Digital CV redesign — richer, responsive, card-based experience

**Feature Branch**: `002-digital-cv-redesign`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "Redesign the digital CV into a richer, responsive, card/section-based
experience. The digital page is deliberately simple today because the same markup auto-generates the
PDF; the drawback is the digital version is too plain and the (long) CV is hard to navigate. Make the
digital (screen) experience more visually appealing and navigable — cards, sections, tasteful
animation — across mobile/tablet/desktop, while keeping the PDF simple and auto-generated and
preserving the digital↔PDF cross-links (screen Download-PDF button; print QR to the page). Decouple
the rich screen presentation from the simple print output. Build an automated responsive/visual +
PDF-render test gate FIRST, enforced on PRs. No backend/DB/API; content unchanged; framework
migration out of scope unless strictly necessary."

## Clarifications

### Session 2026-07-02

- Q: How should the automated rendering check decide the page renders correctly across breakpoints? → A: **Visual-regression snapshots** — screenshot each breakpoint and diff against committed baselines.
- Q: How should a visitor navigate the long CV's sections on the digital page? → A: A **sticky section navigation** (section links that jump/scroll to sections; collapses to a menu on mobile).
- Q: How much animation? → A: **Subtle** — micro-interactions + gentle scroll-reveal, reduced-motion-aware, no layout shift.
- Q: Which viewport breakpoints should the redesign target and the check enforce? → A: **Bootstrap's full breakpoint set** (xs / sm / md / lg / xl / xxl).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rendering can't silently break (Priority: P1)

As the CV maintainer, I want an automated check that the page renders correctly on mobile, tablet,
and desktop **and** that the PDF still renders, running as a required check on every pull request, so
I can change the design confidently and never ship a broken layout or a broken PDF.

**Why this priority**: It is the safety net that makes the rest of the redesign safe, and it already
delivers value against the *current* page (regression protection) before any visual change lands.
Tests-first: it locks today's good behavior so later stories can't regress it unnoticed.

**Independent Test**: Open a PR that deliberately breaks a breakpoint layout (e.g. introduces
horizontal overflow on mobile) or breaks PDF generation → the check fails and blocks the PR; revert →
the check passes.

**Acceptance Scenarios**:

1. **Given** a change that renders correctly at all target breakpoints and still produces a valid
   PDF, **When** a PR is opened, **Then** the rendering check passes.
2. **Given** a change that introduces horizontal overflow (or hides a key section) at a mobile
   breakpoint, **When** a PR is opened, **Then** the rendering check fails and reports which
   breakpoint/section regressed.
3. **Given** a change that breaks PDF generation, **When** a PR is opened, **Then** the check fails
   before anything is published.
4. **Given** a contributor before pushing, **When** they run the check locally, **Then** they get the
   same pass/fail result as CI.

---

### User Story 2 - Navigable, card/section-based digital CV (Priority: P2)

As a visitor (often a recruiter on a phone), I want the long CV presented as clear sections and cards
with easy navigation, so I can scan it and jump to what's relevant quickly on any device.

**Why this priority**: This is the core user-facing improvement — turning a long, plain page into a
scannable, appealing experience — and the main reason for the initiative.

**Independent Test**: Load the page on representative phone, tablet, and desktop viewports → content
is organized into sections/cards, navigation between sections works, nothing overflows, and the PDF
is unchanged (still a clean linear document).

**Acceptance Scenarios**:

1. **Given** the digital page on a desktop viewport, **When** it loads, **Then** the CV is presented
   as distinct sections with card-based content and a visible way to navigate between sections.
2. **Given** the digital page on a mobile viewport, **When** the visitor scans it, **Then** sections
   and cards reflow to a single-column, legible layout with no horizontal scrolling.
3. **Given** the redesigned page, **When** the PDF is generated from the same build, **Then** the PDF
   remains a clean, simple, linear document — cards/section-navigation chrome do not appear in it.
4. **Given** the redesigned page, **When** a visitor wants the file, **Then** the on-screen
   "Download PDF" control works and the PDF still contains the QR code linking back to the page.

---

### User Story 3 - Tasteful motion & polish (Priority: P3)

As a visitor, I want subtle, purposeful animation (e.g. content easing in as I scroll, gentle
affordances on cards/navigation), so the page feels modern and polished — without distraction and
without hurting performance or accessibility.

**Why this priority**: A finishing enhancement layered on the P2 structure; valuable but not required
for a usable, navigable redesign.

**Independent Test**: On screen, animations play tastefully and honor a "reduced motion" preference
(no animation when the user opts out); in the PDF, no animation/motion artifacts appear.

**Acceptance Scenarios**:

1. **Given** a visitor with default settings, **When** they scroll/interact, **Then** subtle
   animations enhance the experience without blocking content or causing layout shift.
2. **Given** a visitor with "reduce motion" enabled, **When** they load the page, **Then**
   non-essential animation is disabled and content is fully usable.

---

### Edge Cases

- **Very small screens** (~320px): content stays legible with no horizontal overflow.
- **Very long content / many sections**: navigation still lets a visitor reach any section quickly;
  performance does not degrade noticeably.
- **Print / PDF isolation**: screen-only chrome (cards styling, section navigation, animation) must
  not leak into the print/PDF output, which stays a clean linear document.
- **Reduced-motion / accessibility**: animations respect the OS "reduce motion" setting; the page
  stays keyboard-navigable.
- **Progressive enhancement**: if client-side JS fails to run, the CV content remains readable
  (graceful degradation).
- **Content edits**: adding/removing a CV entry in the content file must not break the layout or the
  rendering checks.
- **Intentional vs. accidental visual change**: because the check is visual-regression, a *deliberate*
  redesign step updates the committed snapshot baselines (a reviewed change), whereas an *unintended*
  visual diff fails the check. Snapshot determinism depends on the vendored fonts (no CDN) and a
  consistent rendering environment.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The digital (screen) CV MUST present content as distinct **sections** with
  **card-based** content, making a long CV easy to scan on mobile, tablet, and desktop.
- **FR-002**: The digital page MUST provide a **sticky section navigation** — section links that
  jump/scroll to each section, collapsing to a menu on mobile — suited to long content. It is
  screen-only (excluded from the PDF).
- **FR-003**: The digital page MUST use **subtle animation** — micro-interactions on cards/navigation
  and a gentle scroll-reveal of sections — that honors the reduced-motion preference and causes no
  layout shift.
- **FR-004**: The page MUST render correctly — no horizontal overflow, key sections visible and
  legible, controls reachable — across **Bootstrap's full breakpoint set (xs / sm / md / lg / xl / xxl)**.
- **FR-005**: The **PDF MUST remain a clean, simple, linear document**; the redesign MUST NOT change
  the PDF's content/form or complicate its generation. The screen and print presentations MAY diverge.
- **FR-006**: The digital↔PDF **cross-links MUST be preserved**: the screen shows a working
  "Download PDF" control; the PDF shows a QR code linking back to the page.
- **FR-007**: An automated **visual-regression** check MUST screenshot the page at each target
  breakpoint and compare against committed baselines, **and** verify the PDF renders correctly; it
  MUST run as a **required check on pull requests** (failure blocks the PR before anything is
  published). Intentional visual changes are accommodated by updating the committed baselines as a
  reviewed step.
- **FR-008**: The automated check MUST be **runnable locally** (a single command) so contributors get
  the same result as CI before pushing.
- **FR-009**: CV **content is unchanged** — it remains sourced from the existing content data file;
  this feature changes presentation and navigation, not content.
- **FR-010**: The site MUST remain a **static build** deployable on the existing platform with **no
  backend, database, or API**; any interactivity is client-side only.
- **FR-011**: The page MUST remain **accessible** — keyboard-navigable, sufficient contrast, and
  respectful of reduced-motion preferences.
- **FR-012**: Local development, the build pipeline, and the existing deploy flow MUST remain intact.

### Key Entities *(include if feature involves data)*

- **CV content sections**: the existing content groups (e.g. header/facts, about, skills, positions,
  additional experience, competitions) sourced from the content data file — the units the redesign
  organizes into sections/cards and navigation. No new content or data source is introduced.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across **all Bootstrap breakpoints (xs/sm/md/lg/xl/xxl)** the page renders with **no
  horizontal scrolling** and every major section visible and legible (verified by the
  visual-regression check).
- **SC-002**: A deliberately introduced responsive regression (e.g. mobile overflow, a hidden
  section), an unintended visual change, or a PDF-render failure is caught by the check **100% of the
  time** and blocks the PR.
- **SC-003**: On a phone, a visitor can reach any major CV section in **under ~5 seconds** using the
  page's navigation, rather than scrolling the entire long page as today.
- **SC-004**: The generated **PDF is unchanged** by the redesign in content and structure — same
  sections in the same linear order, Download-PDF and QR cross-links intact.
- **SC-005**: On a typical mobile connection the page's main content is visible in **under ~2.5
  seconds**, and animations cause **no visible layout jumping** as the page loads.
- **SC-006**: The site still deploys as a **static** artifact (no backend/DB/API introduced).
- **SC-007**: Contributors can run the rendering check locally and reproduce the CI result.

## Assumptions

- The existing Handlebars → HTML + PDF build pipeline is kept; a framework migration is **not**
  undertaken unless planning finds it strictly necessary (deferred decision, out of scope here).
- The existing screen/print CSS split (screen shows Download-PDF, print shows QR) is the seed for
  decoupling the rich screen presentation from the simple print output.
- The repo's existing headless-browser tooling (used today to render the PDF) is a suitable basis for
  the automated rendering checks — no new external service is required.
- Animation is **subtle** (micro-interactions + gentle scroll-reveal), reduced-motion-aware and
  layout-shift-free (clarified 2026-07-02).
- The rendering check uses **visual-regression snapshots** across **all Bootstrap breakpoints**
  (clarified 2026-07-02). Snapshots must render deterministically — relying on the vendored fonts (no
  CDN) and a consistent environment (the pinned headless browser in CI) to avoid cross-environment
  flakiness; committed baselines are updated as a reviewed step for intentional visual changes.
- CV content continues to live in the existing content data file; no CMS/API is added.
- "Recruiter on a phone" is the primary audience for the digital experience; the PDF serves formal/
  offline sharing.
