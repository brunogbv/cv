# Spec-driven development

Non-trivial features here are developed spec-first with [GitHub spec-kit](https://github.com/github/spec-kit).
A spec captures *intent* — the what and why — before any code, and lives in `specs/<feature>/` as
the source of truth for the change.

## The flow

Run these `/speckit-*` skills in Claude Code (installed under `.claude/skills/`):

1. `/speckit-constitution` — establish or amend the project principles
   (`.specify/memory/constitution.md`).
2. `/speckit-specify` — turn a feature description into a spec (`specs/<feature>/spec.md`).
3. `/speckit-clarify` — resolve ambiguities in the spec before planning (recommended; skip only
   when the spec is already unambiguous). It asks up to 5 targeted questions and records the
   answers back into the spec.
4. `/speckit-plan` — produce the technical implementation plan.
5. `/speckit-tasks` — break the plan into actionable tasks.
6. `/speckit-implement` — execute the tasks.

Optional quality steps: `/speckit-analyze` (read-only spec↔plan↔tasks consistency check, run after
`/speckit-tasks` and before `/speckit-implement`), `/speckit-checklist` (requirements checklists),
and `/speckit-converge` (assess the codebase and append remaining work).

## How it ties into our conventions

- **Issues are the source of truth for task status.** `/speckit-taskstoissues` turns the generated
  tasks into GitHub issues (under the feature's single milestone, phases tagged with `phase:*` — see
  [contributing.md](contributing.md)) **and rewrites each task line in `tasks.md`, repurposing its
  checkbox into a link to the issue** (`- [ ] T001 …` → `- [T001](…/issues/12) …`). After that,
  `tasks.md` is the **decomposition + issue map**, not a status file: a task is done when its linked
  issue closes (via a PR's `Closes #<n>`), and the **milestone progress bar** is the status view.
  `/speckit-implement` does **not** tick checkboxes — don't hand-maintain status in the file.
- **PRs** — implement on a branch and link the issue with `Closes #<n>`.
- **Builds** — `/speckit-implement` runs builds and PDF rendering in the Dev Container or CI, not
  the host (`make page-container`) — see [local-development.md](local-development.md).
- **Self-review** — the ">10 reviewable lines → `/code-review`" gate still applies to spec-driven
  changes.
- **Constitution** — `.specify/memory/constitution.md` reflects and defers to
  [`AGENTS.md`](../AGENTS.md); keep the two consistent.

## Prerequisites

Python, uv, and the `specify` CLI are provided by the [Dev Container](../.devcontainer/devcontainer.json).
Outside it, install the CLI with:

```sh
uv tool install --from git+https://github.com/github/spec-kit.git specify-cli
```
