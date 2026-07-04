# Tasks: Digital CV — interactive editorial deck

**Input**: Design documents from `specs/003-interactive-card-rails/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/interaction-contract.md, quickstart.md

**Tests**: This feature is guarded by the existing **visual-regression + PDF-visual gate** (from 002,
PDF check added in #164), so gate/baseline tasks are first-class and in scope; there is no unit suite.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3 / US4 / US5 (Setup, Foundational, and Polish tasks carry no story label)

**Organization**: US1 is the interactive skeleton (full-viewport native-snap deck — the MVP). US2 adds
the summary-card rails + detail overlays. US3 is the editorial restyle. US4 hardens accessibility /
no-JS / reduced-motion. US5 adds the Through-Line signature + polish. Screen-only throughout; the PDF
stays clean/linear Roboto. Screen baselines are regenerated once the visual stories land (Polish);
the PDF baseline must stay unchanged.

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 [P] Add `@fontsource-variable/fraunces` and `@fontsource-variable/spline-sans` (OFL-1.1) as **devDependencies** in `package.json`, pinned `^5` like `@fontsource/roboto`
- [ ] T002 Extend the `vendoredAssets` array in `src/build.js` to copy, into `dist/vendor/`, Fraunces `opsz.css` + Spline Sans `wght.css` and their latin (plus the CSS-referenced latin-ext / vietnamese) `woff2` files — mirroring the Roboto copy entries
- [ ] T003 Link the two vendored font stylesheets in the `<head>` of `src/templates/index.html` (after the Roboto links); optionally add screen-only `<link rel="preload" as="font" type="font/woff2" crossorigin>` for the two latin `woff2`

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ MUST complete before the user-story phases.**

- [ ] T004 Confirm/extend the `.js`-on-`<html>` before-paint bootstrap (reuse the `src/assets/reveal.js` pattern) so every progressive-enhancement script gates on `.js` and content stays fully visible with no JS — `src/templates/index.html`, `src/assets/reveal.js`
- [ ] T005 Establish the screen/print CSS scaffolding in `src/assets/styles.css`: a screen-only editorial block under `@media not print` and a matching `@media print` "flatten to linear Roboto" block, so every subsequent story layers screen-only rules without leaking into the PDF
- [ ] T006 Extend the deterministic snapshot harness for the deck in `tests/visual.spec.js` (+ `tests/snapshot.css`): `history.scrollRestoration='manual'`, scroll to top, ensure no `:target` overlay is open, `await document.fonts.ready`, normalize scrollbars; keep Playwright `animations:'disabled'` and allow a small `maxDiffPixelRatio` for subpixel snap jitter

---

## Phase 3: User Story 1 - Full-viewport section deck (Priority: P1) 🎯 MVP

**Goal**: Each section fills the viewport; one wheel/trackpad/touch gesture or Arrow/Page press advances
exactly one section and rests centred, via native CSS Scroll Snap (no JS scroll-jacker).

**Independent Test**: Quickstart Scenarios 1–2 — on desktop (wheel, trackpad, keys) and mobile, each
gesture/press advances one section and rests centred (never between); tall panels relax; the page never
scrolls horizontally; the PDF is unchanged.

- [ ] T007 [US1] Deck panels in `src/assets/styles.css` (screen-only): `header` + `.cv-section` → `min-height:100vh`, flex column, `justify-content:center`, `scroll-snap-align:start`, `scroll-snap-stop:always`, `scroll-margin-top:0`; set `html { scroll-snap-type: y mandatory }`
- [ ] T008 [US1] Tall-panel relaxation in `src/assets/styles.css`: a panel whose content exceeds the viewport scrolls internally (mandatory snap only for panels that fit) — applies at all breakpoints
- [ ] T009 [US1] Reduced-motion handling in `src/assets/styles.css`: gate `html { scroll-behavior: smooth }` behind `@media (prefers-reduced-motion: no-preference)`; snapping is retained under reduce
- [ ] T010 [US1] Create `src/assets/deck.js` (progressive enhancement): one-section-per-keypress via `el.scrollIntoView({behavior})` for Arrow/Page keys; ignore auto-repeat (`e.repeat`), form fields, and when an overlay is open; `behavior:'auto'` under reduced-motion; never intercept `wheel`/`touch`
- [ ] T011 [US1] Reference `src/assets/deck.js` from `src/templates/index.html` (screen-only, `.js`-gated) and confirm `src/build.js` copies it to `dist/`
- [ ] T012 [US1] `@media print` rules in `src/assets/styles.css` neutralize the deck (no `100vh` / flex-centering / snap) so the PDF renders linear
- [ ] T013 [US1] Verify US1 against quickstart Scenarios 1–2 (rest-on-a-section, one-per-gesture incl. hard trackpad flick, mobile + tall panels, no horizontal page scroll)

---

## Phase 4: User Story 2 - Summary-card rails + detail overlay (Priority: P2)

**Goal**: The 3 content-dense sections become horizontal rails of short summary cards; activating a card
opens the full entry in a full-screen detail overlay (`:target` baseline).

**Independent Test**: Quickstart Scenario 3 — swipe a rail without moving the deck; open a card to full
detail; close (visible control / outside / Esc) returns to the section centred; background locked.

- [ ] T014 [US2] Summary-card rail markup in `src/templates/index.html` for `positions`, `experience`, `competitions`: a `<ul>` of `<li>` cards, each an `<a href="#pN" target="_self">` with period / title / teaser
- [ ] T015 [US2] Detail-overlay markup in `src/templates/index.html`: one `#pN` overlay per entry with `role="dialog" aria-modal="true" aria-labelledby`, a backdrop close `<a href="#experience" target="_self">`, a **visible** close control (`target="_self"`), and the full `contents` + skill badges
- [ ] T016 [US2] Rail CSS in `src/assets/styles.css` (screen-only): `overflow-x:auto; scroll-snap-type:x mandatory`; cards `flex:0 0 clamp(...)` + `min-width:0` + `scroll-snap-align:start`; `scroll-padding-inline` peek; `overscroll-behavior:contain`; `touch-action:pan-x pan-y`; the `<li>` (not the `<a>`) is the flex/scroll item
- [ ] T017 [US2] Overlay CSS in `src/assets/styles.css` (screen-only): `:target` show/hide, fixed full-screen focused card on a dimmed/blurred backdrop, `body:has(<overlay>:target){overflow:hidden}` scroll-lock, inner scroller `overscroll-behavior:contain`
- [ ] T018 [US2] Create `src/assets/overlay.js` (progressive enhancement): on `hashchange`, move focus into the open overlay, **trap** Tab within it, **return** focus to the triggering card on close; mark the background container `inert` (feature-detect → `aria-hidden` fallback); Escape closes via `location.hash='experience'`
- [ ] T019 [US2] Reference `src/assets/overlay.js` from `src/templates/index.html` (screen-only, `.js`-gated) and confirm it is copied to `dist/`
- [ ] T020 [US2] `@media print` rules in `src/assets/styles.css`: rails flatten to linearly stacked entries and each entry's full content renders exactly once (`break-inside:avoid`), no rail/overlay chrome — PDF unchanged
- [ ] T021 [US2] Verify US2 against quickstart Scenario 3 (rail swipe isolated from the deck; card → full detail; close returns centred; background does not scroll)

---

## Phase 5: User Story 3 - Editorial reference restyle (Priority: P2)

**Goal**: Screen adopts the editorial identity (Fraunces + Spline Sans, cream/ink/terracotta, eyebrows,
skills chips); the PDF keeps Roboto/linear.

**Independent Test**: Quickstart Scenario 7 (vendored fonts, no CDN request, no layout shift) + Scenario
8 (PDF still Roboto/linear).

- [ ] T022 [US3] Type system in `src/assets/styles.css` (inside `@media not print`): headings → `'Fraunces Variable', serif` with `font-optical-sizing:auto`; `--bs-font-sans-serif → 'Spline Sans Variable', roboto, sans-serif`; leave `@media print` on Roboto
- [ ] T023 [US3] Palette + editorial layout in `src/assets/styles.css` (screen-only): cream/ink/slate/terracotta tokens, no boxy cards, uppercase terracotta eyebrow labels via `data-eyebrow`, generous `clamp()` type scale and spacing
- [ ] T024 [US3] Skills as proficiency chips: chip markup in `src/templates/index.html` + screen-only CSS in `src/assets/styles.css` filling each chip to its `--pct` from the existing `[name, percent]` skill data; print keeps the linear list
- [ ] T025 [US3] Verify US3 against quickstart Scenarios 7–8 (fonts served from `vendor/*`, zero third-party requests, no layout shift; PDF unchanged Roboto/linear)

---

## Phase 6: User Story 4 - Accessible, no-JS, reduced-motion (Priority: P2)

**Goal**: The deck, rails, and overlays are fully usable by keyboard and screen reader, degrade with no
JS, and respect reduced-motion.

**Independent Test**: Quickstart Scenarios 4–6 — keyboard/SR full traversal incl. overlay focus
trap+return; JS-off 100% reachable; reduce-motion suppresses only the tween.

- [ ] T026 [US4] ARIA structure + visible focus in `src/templates/index.html` and `src/assets/styles.css`: sections as labelled regions, rails as labelled lists, overlay dialog labelling; visible focus rings not clipped by rails/scroll-padding
- [ ] T027 [US4] No-JS verification (quickstart Scenario 5): with JS disabled, the deck snaps, rails scroll, overlays open/close via `:target`, the Through-Line is static jump links; fix anything gated behind JS
- [ ] T028 [US4] Reduced-motion verification (quickstart Scenario 6) across deck/rails/overlay/signature: snapping kept, glides + transitions + fills suppressed
- [ ] T029 [US4] Keyboard + screen-reader verification (quickstart Scenario 4): full traversal; overlay focus moves in, traps, and returns to the triggering card

---

## Phase 7: User Story 5 - The Through-Line signature + polish (Priority: P3)

**Goal**: One distinctive, on-brand signature — a fixed terracotta thread down the left margin with a
node per section that fills as you snap; doubles as progress/section-nav.

**Independent Test**: Quickstart Scenario 9 — fill advances one hop per snap; on-brand; absent in the
PDF; no layout shift.

- [ ] T030 [US5] Through-Line markup in `src/templates/index.html`: a `.screen` fixed nav with an `<ol>` of section anchor-nodes (`<a href="#..." target="_self">`), `aria-label`, one node per section
- [ ] T031 [US5] Through-Line CSS in `src/assets/styles.css` (screen-only): fixed left-gutter hairline, node per section, `--progress`-driven fill, terracotta `aria-current` node, collapses on narrow viewports; `position:fixed` (no layout shift); absent in `@media print` via `.screen`
- [ ] T032 [US5] Through-Line JS in `src/assets/deck.js`: reuse the section IntersectionObserver to set `--progress` + `aria-current` + an `aria-live` "Section N of M"; reduced-motion → jump not tween; no-JS → static index
- [ ] T033 [US5] Verify US5 against quickstart Scenario 9 (one hop per snap; disciplined/on-brand; absent in PDF; CLS ≈ 0)

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T034 [P] Regenerate and commit the 6 screen baselines (`make visual-update`, reviewed) and confirm the **PDF visual baseline is UNCHANGED** (the screen-only guardrail) — `tests/__screenshots__/`
- [ ] T035 [P] Update `docs/architecture.md`: the deck / rails / detail overlays, the vendored Fraunces + Spline Sans, and the screen/print split for 003
- [ ] T036 [P] Add `docs/adr/0004-*.md`: the decision to build the interactive CV as a native-scroll-snap editorial deck (context, decision, consequences)
- [ ] T037 Run `make lint` and `make visual` green locally (pinned image), then open the PR linking the US issues (`Closes #<n>`) and confirm the Vercel deploy preview

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → **Foundational (P2)** → **User Stories (P3–P7)** → **Polish (P8)**.
- Setup (fonts) blocks US3 (restyle uses the fonts). Foundational (`.js` gate + screen/print scaffolding
  + snapshot determinism) blocks all user stories.

### User Story Dependencies

- **US1 (deck)** — depends only on Foundational. The MVP.
- **US2 (rails + overlay)** — builds on the US1 deck panels (a rail lives inside a deck panel; nested
  scroll must not fight the deck). Do after US1.
- **US3 (restyle)** — depends on Setup (fonts) + Foundational; largely independent of US1/US2 (skins the
  same DOM). Can proceed in parallel with US2 once Setup is done.
- **US4 (a11y / no-JS / reduced-motion)** — cross-cutting; verifies US1–US3 + US5. Do after the
  interaction + overlay exist (US1–US2), alongside/after US3.
- **US5 (signature)** — depends on the US1 deck (it tracks section snaps) and the palette token from US3.

### Within Each User Story

- CSS structure → JS enhancement → print flatten → verify. JS tasks depend on their markup/CSS.

### Parallel Opportunities

- **T001** (deps) is [P] with early template work.
- **US3 (restyle)** can run in parallel with **US2 (rails/overlay)** after Setup+Foundational — they
  touch overlapping files (`styles.css`, `index.html`), so coordinate edits or sequence the CSS.
- Polish **T034/T035/T036** are [P] (different files) once the stories land.

## Implementation Strategy

### MVP First (User Story 1 only)

Ship the full-viewport native-snap deck (US1) on the existing 002 look — a complete, testable
increment: one section per gesture, rests centred, PDF unchanged. This is the headline "more
interactive" win and validates the scroll feel end-to-end before layering rails/restyle.

### Incremental Delivery

US1 (deck) → US2 (rails + detail) → US3 (restyle) → US4 (a11y/no-JS hardening) → US5 (signature). Each
lands screen-only with the PDF unchanged; screen baselines are regenerated once the visual stories are
in (Polish T034), with the PDF baseline held as the guardrail.

## Notes

- **Status is tracked in GitHub Issues + the milestone, not this file.** `/speckit-taskstoissues` will
  turn each task into a `003-T###`-scoped issue and rewrite these checkboxes into issue links; a task is
  "done" when its issue closes via a PR's `Closes #<n>`.
- Screen-only throughout; **never** change `src/utils/pdf.js`; the PDF stays clean/linear Roboto.
- Deck + overlay JS MAY be combined into one asset — kept separate here for clarity.
