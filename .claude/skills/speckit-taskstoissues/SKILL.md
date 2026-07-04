---
name: "speckit-taskstoissues"
description: "Convert existing tasks into actionable, dependency-ordered GitHub issues for the feature based on available design artifacts."
argument-hint: "Optional filter or label for GitHub issues"
compatibility: "Requires spec-kit project structure with .specify/ directory"
metadata:
  author: "github-spec-kit"
  source: "templates/commands/taskstoissues.md"
user-invocable: true
disable-model-invocation: false
---


## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before tasks-to-issues conversion)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Outline.
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").
1. **Derive the FEATURE prefix from FEATURE_DIR.** Take the basename of FEATURE_DIR and read its leading numeric feature id (e.g. `specs/003-interactive-card-rails` → FEATURE = `003`). If the basename has no leading numeric id, fall back to the full basename slug (e.g. `specs/interactive-cards` → FEATURE = `interactive-cards`) — never an empty prefix, since an empty FEATURE would both fail to dedup this feature's own issues and spuriously match other features' `<n>-T001` titles, reintroducing the very collision this scoping prevents. You use FEATURE to scope both the dedup match and the created issue titles below, so that per-feature task IDs (`T001`, `T002`, …) do not collide across features. Task IDs restart at `T001` for every feature; without a feature-scoped prefix, feature 003's `T001` would match feature 002's now-closed `T001` issue during dedup and the new issue would be wrongly skipped.
1. **IF EXISTS**: Load `.specify/memory/constitution.md` for project principles and governance constraints.
1. From the executed script, extract the path to **tasks**.
1. Get the Git remote by running:

```bash
git config --get remote.origin.url
```

> [!CAUTION]
> ONLY PROCEED TO NEXT STEPS IF THE REMOTE IS A GITHUB URL

1. **Fetch existing issues for deduplication**: Before creating anything, build the set of task IDs you are about to process from `tasks.md` (each is a `T` followed by three digits, e.g. `T001`) and pair each with its FEATURE-scoped form `<FEATURE>-T001` (e.g. `003-T001`) — this is the id that appears in the created issue titles. Then use the GitHub MCP server's `list_issues` tool to look for issues that already cover those IDs. Do not pass a `state` value, since omitting it makes the tool return both open and closed issues. Request `perPage: 100` to keep the number of calls down, and since the tool uses cursor-based pagination, request pages with the `after` parameter (using the `endCursor` from the previous response). For each issue title, match it against the FEATURE-scoped pattern `\b<FEATURE>-T\d{3}\b` (e.g. `\b003-T\d{3}\b`; word boundaries so tokens like `S003-T001` or `003-T0010` are not matched by mistake; this also recognises titles written as `003-T001 ...`, `003-T001: ...` or `[003-T001] ...`) and, when it matches one of your feature-scoped task IDs, mark that ID as already having an issue. Match on the feature-scoped pattern — **not** the bare `\bT\d{3}\b` — because task IDs restart at `T001` for every feature, so a bare match would collide with prior features' now-closed `T001…` issues and wrongly skip creating all the new ones. Stop paginating as soon as every feature-scoped task id has been matched, or when there are no more pages, so you do not keep fetching the whole repository's issue history once all task IDs are accounted for. This bounds the number of calls on repos with large issue histories and still prevents duplicates when the command is re-run after `tasks.md` is regenerated or the skill is re-invoked.
1. For each task in the list, use the GitHub MCP server to create a new issue in the repository that is representative of the Git remote. Task lines in `tasks.md` start with a markdown checkbox, so first strip the leading `- [ ]` (and any `[P]` / `[US#]` markers) to recover the task ID and its description. Create the issue with a single canonical title of the form `<FEATURE>-T001: <description>`, prefixing the in-file task ID with the FEATURE prefix derived earlier and writing it once followed by the task description (for example, with FEATURE `003`, the line `- [ ] T001 Create project structure` becomes the title `003-T001: Create project structure`).
   - **Skip** any task whose FEATURE-scoped id (`<FEATURE>-T<nnn>`, e.g. `003-T001`) is already present in the set of existing issues from the previous step, and report it (for example, `003-T001 already has an issue, skipping`). Look up each task by its feature-scoped form, not its bare `T<nnn>` — the dedup set is keyed by the feature-scoped id.
   - Only create issues for tasks that do not yet have a matching issue.

1. **Link each task to its issue in `tasks.md`** — GitHub Issues (plus the milestone progress bar), *not* the file, are the source of truth for task status, so repurpose each task's leading checkbox into a Markdown link to its issue. For **every** task (whether its issue was just created now or already existed from the dedup step), rewrite that task's line in `tasks.md`: replace the leading `- [ ] ` / `- [x] ` / `- [X] ` with `- [<TaskID>](<issue html_url>) `, preserving any `[P]` / `[US#]` markers and the description. Example: `- [ ] T001 [P] Create project structure` becomes `- [T001](https://github.com/<owner>/<repo>/issues/12) [P] Create project structure`. **Idempotent:** if a task's line is already a link (it starts with `- [T001](`), leave it unchanged. The in-file link stays keyed by the bare in-file task id (`T001`), matching the id written in `tasks.md`; only the issue *title* carries the FEATURE prefix. This makes the task↔issue link bidirectional (the issue title carries `<FEATURE>-T001:`, e.g. `003-T001:`) and is why `/speckit-implement` no longer ticks checkboxes — status is tracked by the issues and the milestone, not by the file.

> [!CAUTION]
> UNDER NO CIRCUMSTANCES EVER CREATE ISSUES IN REPOSITORIES THAT DO NOT MATCH THE REMOTE URL

## Post-Execution Checks

**Check for extension hooks (after tasks-to-issues conversion)**:
Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_taskstoissues` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- When constructing slash commands from hook command names, replace dots (`.`) with hyphens (`-`). For example, `speckit.git.commit` → `/speckit-git-commit`.
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
    After emitting the block above you MUST actually invoke the hook and wait for it to finish before continuing. Run it the same way you would run the command yourself in this agent/session (the invocation may differ from the literal `{command}` id shown above, e.g. a skills-mode agent runs it as `/skill:speckit-...` or `$speckit-...`). Emitting the block alone does not run the hook.
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently
