# Spec-driven development

Non-trivial features here are developed spec-first with [GitHub spec-kit](https://github.com/github/spec-kit).
A spec captures *intent* — the what and why — before any code, and lives in `specs/<feature>/` as
the source of truth for the change.

## The flow

Run these `/speckit-*` skills in Claude Code (installed under `.claude/skills/`):

1. `/speckit-constitution` — establish or amend the project principles
   (`.specify/memory/constitution.md`).
2. `/speckit-specify` — turn a feature description into a spec (`specs/<feature>/spec.md`).
3. `/speckit-plan` — produce the technical implementation plan.
4. `/speckit-tasks` — break the plan into actionable tasks.
5. `/speckit-implement` — execute the tasks.

Optional quality steps: `/speckit-clarify` (de-risk ambiguity before planning), `/speckit-analyze`
(cross-artifact consistency), `/speckit-checklist` (requirements checklists), and `/speckit-converge`
(assess the codebase and append remaining work).

## How it ties into our conventions

- **Issues** — `/speckit-taskstoissues` turns the generated tasks into GitHub issues; keep them
  under the feature's milestone (see [contributing.md](contributing.md)).
- **PRs** — implement on a branch and link the issue with `Closes #<n>`.
- **Self-review** — the ">10 reviewable lines → `/code-review`" gate still applies to spec-driven
  changes.
- **Constitution** — `.specify/memory/constitution.md` restates the principles in
  [`AGENTS.md`](../AGENTS.md); keep the two consistent.

## Prerequisites

Python, uv, and the `specify` CLI are provided by the [Dev Container](../.devcontainer/devcontainer.json).
Outside it, install the CLI with:

```sh
uv tool install --from git+https://github.com/github/spec-kit.git specify-cli
```
