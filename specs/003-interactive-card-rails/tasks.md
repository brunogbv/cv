# Tasks: Digital CV — interactive swipeable card rails

**Input**: Design documents from `specs/003-interactive-card-rails/`

**Prerequisites**: plan.md, spec.md, research.md, design.md, data-model.md, contracts/, quickstart.md

**Tests**: This feature is guarded by the existing visual-regression + PDF-render gate (from 002), so
gate/baseline tasks are first-class and explicitly in scope; there is no separate unit suite.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3 (Setup, Foundational, and Polish tasks carry no story label)

**Organization**: US1 is a complete CSS-only, accessible, PDF-safe rail (the MVP). US2 adds the
progressive-enhancement JS affordances + rigorous a11y/no-JS verification. US3 adds the signature +
polish. Each US2/US3 change ships with a reviewed baseline update.

## Phase 1: Setup

No standalone setup — reuses the 002 tooling (the Playwright gate, `@playwright/test`, `make visual` /
`make visual-update`, the pinned image). No new dependency, framework, or vendored font (plan.md,
Principle V).

## Phase 2: Foundational (Blocking Prerequisites)

- [T001](https://github.com/brunogbv/cv/issues/135) Extend the rail snapshot **determinism** harness so rail resting state is stable: in
      `tests/visual.spec.js` set `history.scrollRestoration = 'manual'`, reset each rail's
      `scrollLeft = 0`, and disable smooth scroll before capture; normalize the scrollbar in
      `tests/snapshot.css`. Allow a small `maxDiffPixelRatio` in `playwright.config.js` if needed
      (research D6, contract "Gate"). Blocks US1 baselines.

## Phase 3: User Story 1 — Swipeable card rails (Priority: P1) 🎯 MVP

**Goal**: The three dense sections are horizontally swipeable, snapping, one-focal-card-with-peek
rails; keyboard-scrollable; the page never overflows horizontally; the PDF is unchanged. CSS-only —
fully functional with no JavaScript.

**Independent test**: quickstart Scenarios 1, 6, 7 — rails swipe/snap across breakpoints with no page
overflow; the PDF is unchanged; the gate is green.

- [T002](https://github.com/brunogbv/cv/issues/136) [US1] Restructure the three dense sections in `src/templates/index.html`: wrap each
      section's entries in a focusable, labelled scrollable region (`role="region"` + `aria-label` +
      `tabindex="0"`) containing a `<ul>` of card `<li>`s (data-model.md, contract "Structure").
      Header, About, and Skills stay unchanged.
- [T003](https://github.com/brunogbv/cv/issues/137) [US1] Add screen rail layout to `src/assets/styles.css`: `scroll-snap-type: x mandatory`;
      cards `flex: 0 0 clamp(min, sub-100%, max)` + `min-width: 0` + `scroll-snap-align: start`;
      `scroll-padding-inline` peek gutter; `overscroll-behavior-x: contain`. The **page must never
      scroll horizontally** (research D4, contract "Screen", SC-002).
- [T004](https://github.com/brunogbv/cv/issues/138) [US1] Add focus handling in `src/assets/styles.css`: visible focus on the region and card
      links; `scroll-padding` + `outline-offset` so focus rings are not clipped by the track
      (research D2; WCAG 2.4.7 / 2.4.11).
- [T005](https://github.com/brunogbv/cv/issues/139) [US1] Extend `@media print` in `src/assets/styles.css`: rails **flatten** — region is not a
      scroller, cards stack linearly, `break-inside: avoid` per entry, no rail chrome (contract
      "Print"). No change to `src/utils/pdf.js`.
- [T006](https://github.com/brunogbv/cv/issues/140) [US1] Gate the smooth-scroll glide behind `@media (prefers-reduced-motion: no-preference)`
      in `src/assets/styles.css` (CSS-only for US1; snapping stays always-on) (research D5).
- [T007](https://github.com/brunogbv/cv/issues/141) [US1] Regenerate the committed baselines (`make visual-update`) for the rails' resting
      state; confirm `make visual` is green across all 6 breakpoints; commit `tests/__screenshots__/`
      (reviewed).
- [T008](https://github.com/brunogbv/cv/issues/142) [US1] Verify the **PDF is unchanged**: build and compare the generated PDF page-for-page
      against a pre-003 build (quickstart Scenario 6) — rails flattened, entries/order intact,
      QR + Download-PDF present.

**Checkpoint**: CSS-only accessible rails work and are gated; the PDF is untouched. Shippable MVP.

## Phase 4: User Story 2 — Accessible and works without JavaScript (Priority: P2)

**Goal**: Rigorous a11y + the additive JS affordance layer — SR-exposed list, keyboard operable,
no-JS reachability, reduced-motion, prev/next + position status.

**Independent test**: quickstart Scenarios 2–5 — keyboard/SR navigation works; JS-off leaves all
content reachable; reduced-motion suppresses non-essential motion.

- [T009](https://github.com/brunogbv/cv/issues/143) [US2] Add `src/assets/rails.js` (progressive enhancement, screen-only effect): per-rail
      prev/next controls, an `aria-live` position status, reduced-motion-aware scrolling (branch on
      `matchMedia('(prefers-reduced-motion: reduce)')`), and **fail-visible** behavior (any error
      leaves all content reachable). Reference it from `src/templates/index.html`; it is copied to
      `dist/` by the existing `src/assets` copy (research D3, contract "Progressive enhancement").
- [T010](https://github.com/brunogbv/cv/issues/144) [US2] Style the prev/next controls + position status in `src/assets/styles.css`
      (screen-only; hidden in `@media print`); meet target-size (≥24px) and non-text contrast; absent
      / harmless when JS does not run.
- [T011](https://github.com/brunogbv/cv/issues/145) [US2] Verify accessibility + progressive enhancement (quickstart Scenarios 2–5): keyboard
      reaches and moves through each rail with visible focus; a screen reader announces a labelled list
      of N cards + position changes; **JS disabled → all cards reachable, nothing hidden**;
      reduced-motion → no glide/animation. Update baselines if the resting state changed.

**Checkpoint**: rails are fully accessible and degrade gracefully with no JS.

## Phase 5: User Story 3 — Signature "route between nodes" & polish (Priority: P3)

**Goal**: the distinctive, on-brand route-indicator signature + subtle rail polish; none of it in the
PDF.

**Independent test**: quickstart Scenario 8 — the route indicator tracks position, active node in the
signal accent, reduced-motion respected, absent in the PDF, no layout shift.

- [T012](https://github.com/brunogbv/cv/issues/146) [US3] Implement the **"route between nodes"** position indicator: CSS in
      `src/assets/styles.css` (ordered nodes + connecting line; active node in the `signal` red) wired
      to the rail position in `src/assets/rails.js` (and used as the `aria-live` target);
      reduced-motion-aware pulse; screen-only (absent in `@media print`) (design.md, FR-008).
- [T013](https://github.com/brunogbv/cv/issues/147) [US3] Add subtle focused-card emphasis + rail affordance polish in `src/assets/styles.css`
      — reduced-motion-aware, **no layout shift** (FR-009, SC-008).
- [T014](https://github.com/brunogbv/cv/issues/148) [US3] Update the committed baselines (`make visual-update`) for the signature/polish resting
      state; confirm `make visual` green; verify the signature is **absent in the PDF** (quickstart
      Scenario 8).

**Checkpoint**: full interactive redesign complete, guarded by the gate.

## Phase 6: Polish & cross-cutting

- [T015](https://github.com/brunogbv/cv/issues/149) [P] Update `docs/architecture.md`: the card rails, `src/assets/rails.js`, and the
      screen/print rail decoupling.
- [T016](https://github.com/brunogbv/cv/issues/150) [P] Update `docs/ci-cd.md` if the Visual gate's rail-determinism setup changed.
- [T017](https://github.com/brunogbv/cv/issues/151) [P] Update `AGENTS.md` if any convention changed (e.g. the `rails.js` progressive-enhancement
      asset pattern).
- [T018](https://github.com/brunogbv/cv/issues/152) [P] Add ADR `docs/adr/0004-interactive-card-rails.md` (CSS scroll-snap rails +
      accessible-region pattern + the routing signature + no-JS-first decision); index it in
      `docs/adr/README.md`.
- [T019](https://github.com/brunogbv/cv/issues/153) Final verification: run quickstart Scenarios 1–8; `make lint` and `make visual` green;
      confirm SC-001…SC-008.

## Dependencies & execution order

- **Foundational (T001)** → **US1 (T002–T008)** → **US2 (T009–T011)** → **US3 (T012–T014)** →
  **Polish (T015–T019)**.
- US2 and US3 depend on US1 (the rail structure must exist; each then updates baselines intentionally).
- Within US1: T002 (template) → T003/T004/T006 (styles.css, sequential — same file) → T005 (print) →
  T007 (baselines, needs T001) → T008 (PDF verify).
- Polish T015–T018 are independent files (parallel); T019 is last (depends on everything).

## Parallel opportunities

- **US1**: T002 (`index.html`) can start alongside the first `styles.css` task, but T003/T004/T005/T006
  all edit `src/assets/styles.css` and must be sequential.
- **Polish**: T015, T016, T017, T018 touch four independent files → parallel.

## Implementation strategy

- **MVP = US1** — a complete, accessible, CSS-only rail with the PDF untouched; delivers the headline
  interaction and is independently shippable.
- Then US2 (the JS affordance layer + a11y/no-JS hardening), then US3 (the signature + polish). Each
  US2/US3 change ships as code **plus a reviewed baseline update** — the gate makes every visual change
  explicit.
- Polish (docs + ADR + final verification) lands with or right after the stories it documents. No
  constitution amendment is needed (v1.3.0 already recognizes the visual gate).
