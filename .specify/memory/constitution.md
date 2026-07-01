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

### IV. Validate locally; CI is the gate

Linting (Super-Linter) is the only automated CI gate — reproduce it with `make lint` before
pushing. There is no test suite; quality comes from lint + self-review + verifying the generated
PDF. Keep the feedback loop local and fast.

### V. Reproducible and minimal

Pin what determines output (Node 22, Playwright's Chromium via the lockfile); prefer arch-native
builds over emulation. Add only what is needed — minimal dependencies, minimal commands, minimal
config.

## Development Workflow

Work is tracked in GitHub — one Milestone per shippable deliverable, its Issues tagged with
type/phase labels for grouping; Projects are optional. Non-trivial features are spec-driven:
`/speckit-specify` → `/speckit-clarify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`,
with the spec living in `specs/<feature>/` as the source of intent. Every change lands via a branch
and a PR that links its issue with `Closes #<n>`.

## Governance

This constitution reflects and defers to [`AGENTS.md`](../../AGENTS.md); amendments update both and
keep them consistent. All PRs are expected to comply, and added complexity must be justified.

**Version**: 1.0.2 | **Ratified**: 2026-07-01 | **Last Amended**: 2026-07-02
