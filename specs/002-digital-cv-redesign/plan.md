# Implementation Plan: Digital CV redesign — richer, responsive, card-based experience

**Branch**: `002-digital-cv-redesign` | **Date**: 2026-07-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-digital-cv-redesign/spec.md`

## Summary

Make the **digital (screen)** CV a richer, responsive, card/section-based experience with a sticky
section navigation and subtle, accessible animation — while keeping the **PDF** the same clean linear
document and preserving the digital↔PDF cross-links. The work is **tests-first**: stand up a
Playwright **visual-regression + PDF-render gate** (required on PRs) that locks today's rendering,
then build the redesign against it. Everything stays a **single Handlebars source + one CSS file**;
the rich screen chrome lives in the `@media screen` cascade and `@media print` strips it back to the
existing linear PDF (`page.pdf()` already renders print media — `pdf.js` is untouched). See
[research.md](research.md) for the decisions.

## Technical Context

**Language/Version**: JavaScript on Node.js 22 (existing build: `node src/build.js`); Handlebars
templates; Bootstrap 5.2; hand-written CSS.

**Primary Dependencies**: existing — `handlebars`, `playwright@1.61.1` (PDF render), `fs-extra`,
`dayjs`, `speakingurl`, `markdown`, `@fontsource/roboto` + `@fortawesome/fontawesome-free` +
`bootstrap` (vendored into `dist/`). **New (dev only)**: `@playwright/test@1.61.1` (test runner +
`toHaveScreenshot`). Client-side: a few lines of vanilla JS (IntersectionObserver reveal); **no
framework, no runtime deps, no animation library**.

> **Maintenance constraint**: `playwright` and `@playwright/test` MUST stay pinned to the **same**
> version (currently `1.61.1`) so they share the one pinned Chromium (no duplicate download / no
> render drift). If one is bumped, bump both together.

**Storage**: N/A — static site; CV content stays in `src/metadata/metadata.js`.

**Testing**: Playwright (`@playwright/test`) — **visual-regression snapshots** at 6 Bootstrap
breakpoints (375/576/768/992/1200/1440, `fullPage`) + a **PDF-render** check (exists / non-empty /
`%PDF-` header). Baselines committed, generated only in the Linux Dev Container / CI. This is the
repo's **first** automated test suite.

**Target Platform**: static hosting on Vercel; modern evergreen browsers; PDF via headless Chromium.

**Project Type**: single static web project (no backend).

**Performance Goals**: main content visible < ~2.5 s on a typical mobile connection; no visible
layout shift from animation (CLS ≈ 0).

**Constraints**: no backend/DB/API; PDF output unchanged (content + linear form); snapshots must be
deterministic (single Linux baseline env + vendored fonts + tolerance); minimal, pinned deps;
`make` is the interface; builds/tests run in the Dev Container or CI, not the host.

**Scale/Scope**: one CV page, ~6 content sections; 6 breakpoint baselines; 1 new CI workflow.

## Constitution Check

*GATE: evaluated pre-Phase 0 and re-checked post-design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Makefile is the interface | Pass (with action) | New targets `make visual` (build + run tests in Dev Container) and `make visual-update` (reviewed baseline refresh); added to `.PHONY`. |
| II. Self-review before done | Pass | Each implementation PR runs `/code-review` + records the gate (unchanged). |
| III. Docs stay in sync | Pass (with action) | Updates to `docs/ci-cd.md` (new gate), `docs/architecture.md` (screen/print split, tests), `docs/local-development.md` (`make visual*`), `AGENTS.md`; **ADR** for the visual-regression + screen/print-decoupling decision. |
| IV. Validate locally; CI is the gate | **Conflict → amendment required** | Principle IV says lint is the *only* CI gate and there is no test suite; this feature adds both. Resolved by **amending Principle IV** (Principle VI harness evolution) — see Complexity Tracking. Local-fast-loop + Dev-Container rules are honored (`make visual`). |
| V. Reproducible and minimal | Pass | `@playwright/test` pinned to the same `1.61.1` as `playwright`; determinism via the pinned Chromium + vendored fonts + a single Linux baseline env + tolerance. Adds one dev dep + committed baseline PNGs (small). No SaaS, no framework. |
| VI. Harness is a living system | Pass | The Principle IV amendment + the new gate are codified deliberately (constitution + docs + ADR), not patched ad-hoc. |
| Development Workflow (tracking) | Pass | Tasks become GitHub issues via `/speckit-taskstoissues`; status via issues + milestone (per constitution v1.2.0 — needs PR #98 merged before `taskstoissues`). |

**Gate result**: PASS, contingent on the Principle IV amendment (tracked, justified below). No
unjustified violations.

**Principle IV amendment (specifics for `/speckit-tasks`)**: reword the principle's *"There is no
test suite… Linting is the only automated CI gate"* to acknowledge the new gate — e.g. *"Automated CI
gates are Super-Linter (lint) and Playwright (visual-regression + PDF-render); reproduce them locally
with `make lint` and `make visual` before pushing."* Bump the constitution **1.2.0 → 1.3.0** (MINOR —
a principle materially changes) and update **Last Amended**; keep **`AGENTS.md`** consistent (its
Testing Instructions gain the visual gate + `make visual` / `make visual-update`) and document the
workflow in **`docs/ci-cd.md`**.

## Project Structure

### Documentation (this feature)

```text
specs/002-digital-cv-redesign/
├── plan.md              # This file
├── research.md          # Phase 0 decisions
├── data-model.md        # Phase 1 — content sections model
├── quickstart.md        # Phase 1 — how to validate
├── contracts/           # Phase 1 — rendering + test-gate contracts
│   ├── rendering-contract.md
│   └── visual-test-gate-contract.md
└── tasks.md             # Phase 2 (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
src/
├── templates/index.html     # MODIFY: sections + cards + sticky nav (screen-only chrome)
├── assets/
│   ├── styles.css           # MODIFY: extend screen/print split; card/nav/reveal styles; @media print flatten
│   └── reveal.js            # NEW: tiny IntersectionObserver scroll-reveal (+ ".js" root-class gate)
├── metadata/metadata.js     # UNCHANGED (content source)
├── build.js                 # MODIFY only if needed to copy a new JS asset into dist/
└── utils/pdf.js             # UNCHANGED (do NOT add emulateMedia — PDF stays print-media)

tests/                       # NEW — first test suite
├── visual.spec.js           # toHaveScreenshot per breakpoint (fullPage)
├── pdf.spec.js              # PDF exists / non-empty / %PDF- header
├── snapshot.css             # test-only: force .reveal visible for deterministic capture
└── __screenshots__/         # committed Linux baselines

playwright.config.js         # NEW (repo root): breakpoint projects, tolerance, reducedMotion, snapshotPathTemplate
.github/workflows/visual.yml # NEW: required PR check (build + visual + pdf)
Makefile                     # MODIFY: visual, visual-update targets (+ .PHONY)
package.json / lock          # MODIFY: add @playwright/test@1.61.1 (dev)
```

**Structure Decision**: Single static project. The feature adds a **`tests/`** tree and a root
**`playwright.config.js`** — the repo's first test infrastructure — plus screen-only enhancements to
the existing template/CSS and one small client JS file. The PDF pipeline (`pdf.js`) is deliberately
left untouched; screen/print divergence is entirely CSS-driven.

## Complexity Tracking

| Violation | Why needed | Simpler alternative rejected because |
|-----------|------------|--------------------------------------|
| **Amend Constitution Principle IV** (lint-only gate → +visual/PDF gate) | The feature's core value is an automated gate, which inherently adds a test suite + a 2nd CI gate. | Not adding it leaves the redesign unguarded (defeats US1 / SC-002); leaving Principle IV as-is is self-contradictory. Minimal honest fix (Principle VI) — version-bumped, AGENTS.md kept consistent. |
| **First `tests/` tree + `@playwright/test` dev dep + committed baseline PNGs** | Snapshot testing needs a runner, a config, and golden images. | jest-image-snapshot/BackstopJS add more tooling; SaaS (Percy) adds an external dependency + secret. Reusing the already-pinned Playwright is the minimal option. |
