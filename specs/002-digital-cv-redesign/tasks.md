# Tasks: Digital CV redesign — richer, responsive, card-based experience

**Input**: Design documents from `specs/002-digital-cv-redesign/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: This feature's core deliverable **is** an automated test gate (US1), so test tasks are
first-class and explicitly in scope.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3 (Setup, Foundational, and Polish tasks carry no story label)

**Organization**: tests-first. US1 (the visual + PDF gate) is the safety net; US2 (layout) and US3
(animation) are built against it, each intentionally updating the reviewed snapshot baselines.

## Phase 1: Setup (test tooling)

- [T001](https://github.com/brunogbv/cv/issues/100) [P] Add `@playwright/test` pinned to `1.61.1` (exact, same as `playwright`) to
      devDependencies in `package.json` and refresh `package-lock.json`.
- [T002](https://github.com/brunogbv/cv/issues/101) [P] Add `playwright.config.js` at repo root: `testDir: 'tests'`; 6 breakpoint viewports
      (375/576/768/992/1200/1440 = Bootstrap xs/sm/md/lg/xl/xxl); `expect.toHaveScreenshot`
      `{ maxDiffPixelRatio: 0.01, threshold: 0.2, animations: 'disabled' }`; `use.reducedMotion:
      'reduce'`; a platform-neutral `snapshotPathTemplate`; load pages via `file://` `dist/index.html`.
- [T003](https://github.com/brunogbv/cv/issues/102) [P] Create `tests/snapshot.css` (test-only) forcing `.reveal { opacity:1 !important;
      transform:none !important }` for deterministic capture.
- [T004](https://github.com/brunogbv/cv/issues/103) Add `make visual` (build via `make page`, then run Playwright in the Dev Container) and
      `make visual-update` (wraps `playwright test --update-snapshots` in the Dev Container) to the
      `Makefile`, and add both to `.PHONY`.

## Phase 2: Foundational (Blocking Prerequisites)

No standalone foundational tasks. **US1 (Phase 3) is itself the foundation** — the test gate must be
in place before US2/US3 so their visual changes are made explicit and reviewed. US2 and US3 depend on
US1.

## Phase 3: User Story 1 — Rendering can't silently break (Priority: P1) 🎯 MVP

**Goal**: an automated visual-regression + PDF-render check, required on PRs, that locks today's
rendering.

**Independent test**: a deliberate mobile-overflow change or a broken PDF fails the check and blocks
the PR; reverting turns it green (quickstart Scenarios 1–3).

- [T005](https://github.com/brunogbv/cv/issues/104) [P] [US1] Write `tests/visual.spec.js`: `toHaveScreenshot({ fullPage: true })` of
      `dist/index.html` at each of the 6 breakpoints (per `playwright.config.js`).
- [T006](https://github.com/brunogbv/cv/issues/105) [P] [US1] Write `tests/pdf.spec.js`: assert the built `dist/*.pdf` exists, is > ~1 KB, and
      begins with the `%PDF-` header.
- [T007](https://github.com/brunogbv/cv/issues/106) [US1] Generate the initial baselines from the **current** page in the Linux Dev Container
      (`make visual-update`) and commit `tests/__screenshots__/` (the pre-redesign golden reference).
- [T008](https://github.com/brunogbv/cv/issues/107) [US1] Add `.github/workflows/visual.yml` (name `Visual`): `ubuntu-latest`, Node 22,
      `npm ci`, cache `~/.cache/ms-playwright` (keyed on the Playwright version), `npx playwright
      install --with-deps chromium`, `make page`, `npx playwright test`; upload the HTML report + diff
      images as an artifact on failure. Enforce as a required PR check.
- [T009](https://github.com/brunogbv/cv/issues/108) [US1] Verify the gate (quickstart Scenarios 1–3): a forced mobile overflow fails
      `make visual`; a broken PDF fails `pdf.spec`; revert → green.

**Checkpoint**: the safety net exists and is enforced; US2/US3 can proceed.

## Phase 4: User Story 2 — Navigable, card/section-based digital CV (Priority: P2)

**Goal**: rich, responsive card/section layout with a sticky section nav on screen; the PDF stays a
clean linear document.

**Independent test**: page shows sections/cards + working nav across breakpoints with no overflow;
the PDF is unchanged (quickstart Scenario 4).

- [T010](https://github.com/brunogbv/cv/issues/109) [US2] Extend the screen/print split in `src/assets/styles.css`: screen card + section
      styles and sticky-nav styles; `@media print` flattens cards (no border/shadow/background/radius),
      sets the nav `display:none`/static, and adds `break-inside: avoid` to experience/competition
      entries.
- [T011](https://github.com/brunogbv/cv/issues/110) [US2] Restructure `src/templates/index.html`: group content into sections with stable
      `id`s (per data-model.md) + card markup; add the screen-only sticky section nav (in `.screen`)
      with a mobile `<details>` menu; preserve the Download-PDF control (screen) and QR (print).
- [T012](https://github.com/brunogbv/cv/issues/111) [US2] Add reduced-motion-gated `scroll-behavior: smooth` and `scroll-margin-top` for the
      section anchors in `src/assets/styles.css`.
- [T013](https://github.com/brunogbv/cv/issues/112) [US2] Verify: the PDF is unchanged (linear, no nav/card chrome, QR present, content order
      intact); run `make visual-update` to accept the new screen look (reviewed baselines) and confirm
      `make visual` green across all 6 breakpoints (quickstart Scenario 4).

**Checkpoint**: the digital CV is navigable + card-based; the PDF is untouched.

## Phase 5: User Story 3 — Tasteful motion & polish (Priority: P3)

**Goal**: subtle, accessible scroll-reveal animation on screen; none in the PDF; graceful without JS.

**Independent test**: gentle reveal on scroll with no layout shift; reduced-motion → no motion; no-JS
→ content visible; PDF unaffected (quickstart Scenario 5).

- [T014](https://github.com/brunogbv/cv/issues/113) [US3] Add `src/assets/reveal.js`: set a `.js` class on the root, then a one-shot
      IntersectionObserver adding `.is-visible` to `.reveal` elements; ensure `src/build.js` copies it
      into `dist/` and `src/templates/index.html` references it (screen-only).
- [T015](https://github.com/brunogbv/cv/issues/114) [US3] Add reveal/animation CSS to `src/assets/styles.css`: `transform`/`opacity`
      transitions gated behind `.js` **and** `@media (prefers-reduced-motion: no-preference)`; base
      state fully visible (no-JS fallback); `@media print` forces `.reveal` visible + no motion.
- [T016](https://github.com/brunogbv/cv/issues/115) [US3] Verify (quickstart Scenario 5): subtle reveal, CLS ≈ 0; reduced-motion off; no-JS
      shows all content; snapshots deterministic via `tests/snapshot.css`; update baselines if the
      resting state changed; `make visual` green.

**Checkpoint**: full redesign complete, guarded by the gate.

## Phase 6: Polish & cross-cutting

- [T017](https://github.com/brunogbv/cv/issues/116) [P] Amend Constitution Principle IV in `.specify/memory/constitution.md` to acknowledge the
      visual-regression + PDF-render CI gate; bump 1.2.0 → 1.3.0 + update Last Amended.
- [T018](https://github.com/brunogbv/cv/issues/117) [P] Update `AGENTS.md`: Testing Instructions gain the visual gate + `make visual` /
      `make visual-update` + the `tests/` suite (keep consistent with the constitution amendment).
- [T019](https://github.com/brunogbv/cv/issues/118) [P] Update `docs/ci-cd.md`: document the `Visual` workflow, `make visual*`, and the
      baseline-update flow.
- [T020](https://github.com/brunogbv/cv/issues/119) [P] Update `docs/architecture.md`: the `tests/` suite, the screen/print decoupling, and
      `reveal.js`.
- [T021](https://github.com/brunogbv/cv/issues/120) [P] Update `docs/local-development.md`: add `make visual` / `make visual-update` to the
      commands table.
- [T022](https://github.com/brunogbv/cv/issues/121) [P] Add ADR `docs/adr/0003-visual-regression-and-screen-print-decoupling.md` recording the
      decisions (visual-regression tooling + determinism, screen/print decoupling, accessible
      animation) and update `docs/adr/README.md`.
- [T023](https://github.com/brunogbv/cv/issues/122) Final verification: run quickstart Scenarios 1–6; `make lint` and `make visual` green;
      confirm SC-001…SC-007.

## Dependencies & execution order

- **Setup (Phase 1)** → **US1 (Phase 3)** → **US2 (Phase 4)** → **US3 (Phase 5)** → **Polish (Phase 6)**.
- US2 and US3 **depend on US1** (the gate must exist first; each then updates baselines intentionally).
- Within US1: T005/T006 (write tests) before T007 (generate baselines) before T008/T009 (CI + verify).
- Polish T017–T022 are independent files (parallel); T023 is last (depends on everything).

## Parallel opportunities

- **Phase 1**: T001, T002, T003 in parallel (different files); then T004.
- **US1**: T005 and T006 in parallel (separate spec files).
- **Polish**: T017–T022 in parallel (six independent files).

## Implementation strategy

- **MVP = US1** (the gate) — delivers standalone value (regression protection on the current page)
  and unblocks the rest.
- Then US2 (the visible redesign), then US3 (motion). Each US2/US3 change ships as code **plus a
  reviewed baseline update** (see research.md "Baseline cadence") — the gate makes every visual change
  explicit, never blocking intended ones.
- Polish (docs + the Principle IV amendment + ADR) lands with or right after the stories it documents.
