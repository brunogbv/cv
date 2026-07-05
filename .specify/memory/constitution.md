# CV Constitution

The principles that govern how this repository is developed. This formalizes the conventions in
[`AGENTS.md`](../../AGENTS.md); the two must stay consistent.

## Core Principles

### I. The Makefile is the interface

Interact with the repo through the `Makefile`. Every repeatable workflow gets a target, so flags,
container names, volumes, and ordering live in one place; ad-hoc `npm`/`docker` commands are
avoided. New capability → new target (added to `.PHONY`).

### II. Self-review before done (NON-NEGOTIABLE)

Any change over 10 reviewable lines runs `/code-review` and is recorded before it is reported done
or opened as a PR. Enforced locally by the `.claude/hooks/review-gate.sh` Stop hook.

### III. Docs stay in sync

A change that alters behavior, commands, architecture, or workflow updates the relevant docs in the
same PR (`docs/`, `README.md`, `AGENTS.md`). Significant, expensive-to-reverse decisions are
captured as an ADR in `docs/adr/`.

### IV. Validate locally; CI gates are the safety net

Two automated CI gates run on every PR and must pass: **linting** (Super-Linter, `make lint`) and the
**visual-regression + PDF-render check** (Playwright, `make visual`). Reproduce both locally before
pushing. The visual gate snapshots the page at each breakpoint and verifies the PDF renders;
intentional visual changes update the committed baselines (`make visual-update`) as a reviewed step.
There is no *unit/integration* suite — beyond the automated gates, quality still comes from
self-review and inspecting the generated PDF. Keep the feedback loop local and fast. Builds, PDF
rendering, and the visual check run in the Dev Container or CI, not the host — see
[`docs/local-development.md`](../../docs/local-development.md).

### V. Reproducible and minimal

Pin what determines output (Node 22, Playwright's Chromium via the lockfile); prefer arch-native
builds over emulation. Add only what is needed — minimal dependencies, minimal commands, minimal
config.

### VI. The harness is a living system

When a task reveals a systemic gap in the harness (conventions, docs, `.claude/` hooks, the Dev
Container, CI, spec-kit), codify the fix rather than patching the symptom — preferring an executable
gate over a documented practice (Principle VII) — see
[`docs/contributing.md`](../../docs/contributing.md) ("Improving the harness").

### VII. Guardrails over guidance — prefer executable gates (NON-NEGOTIABLE)

Documentation states intent; a **gate enforces it**. For a mistake that is **costly or likely to
recur** — breaking the PDF, shipping a stale visual baseline, leaking a secret, regressing
accessibility — the durable fix is a **deterministic check** (a test, validation, lint rule, hook, or
CI gate that mechanically passes or fails), not a line in a doc asking a fallible human or agent to
remember. Everyone is prone to mistakes; documented best practice relies on memory and diligence at
exactly the moment they lapse. So when a task surfaces such a mistake (Principle VI), reach for a gate
first: make the wrong thing fail loudly and automatically. **What is non-negotiable is that
documentation alone is never the final answer to a real, recurring mistake** — when a gate is
genuinely impractical today, the documented practice is a stopgap that ships *with* a filed `harness`
issue to add the gate. A near-miss on something that matters, caught only by inspection, is itself the
signal that a gate is missing — file it and treat closing that gap as the real fix, not the catch.
(Self-review under Principle II still backstops everything; this principle is about converting the
mistakes that recur or bite hard into gates.)

## Development Workflow

Work is tracked in GitHub — one Milestone per shippable deliverable, its Issues tagged with
type/phase labels for grouping; Projects are optional. Non-trivial features are spec-driven:
`/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` →
`/speckit-taskstoissues` → `/speckit-implement`, with the spec living in `specs/<feature>/` as the
source of intent. `/speckit-taskstoissues` creates each task's GitHub issue and repurposes its
`tasks.md` checkbox into a link to that issue; **GitHub Issues and the milestone progress bar are the
single source of truth for task status** — `tasks.md` is the decomposition + issue map (not a status
file), and `/speckit-implement` does not track status in it. Every change lands via a branch and a PR
that links its issue with `Closes #<n>`.

## Governance

This constitution reflects and defers to [`AGENTS.md`](../../AGENTS.md); amendments update both and
keep them consistent. All PRs are expected to comply, and added complexity must be justified.

**Version**: 1.4.0 | **Ratified**: 2026-07-01 | **Last Amended**: 2026-07-05
