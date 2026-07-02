# Contributing & Issue Tracking

All work on this repo is tracked in **GitHub** — Issues and Milestones, with labels for grouping and
an optional Project board. Open an issue before starting non-trivial work so the change is visible,
reviewable, and linked to its goal.

## Where work lives

| Tool         | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| Issues       | One unit of work — a bug, feature, doc change, or chore.                          |
| Milestones   | **One per shippable thing** — a coherent deliverable/initiative. Groups the issues that deliver it; the progress bar tracks "is this thing done?". Not per-phase or per-task. |
| Labels       | Tag cross-cutting dimensions (**type**, and a **phase**/story label for multi-phase work) so issues filter and group *within or across* milestones — without minting more milestones. |
| Projects     | **Optional** board/field view (kanban, custom fields, cross-milestone). See [Milestones, labels, and projects](#milestones-labels-and-projects). |

## Milestones, labels, and projects

The pattern to follow:

- **Milestone = one per shippable thing.** A milestone is a coherent deliverable whose completion is
  meaningful on its own — an initiative or a release increment (e.g. "Local development with
  devcontainers", "Migrate hosting & CD to Vercel"). Put every issue that makes up that deliverable
  under it, so the milestone's progress bar answers "how close is this thing to done?". **Don't**
  create a milestone per phase or per task — that fragments the one signal you care about and adds
  ceremony. A one-off issue that isn't part of a larger deliverable needs no milestone.
- **Labels = tag the cross-cutting dimensions.** Beyond the required **type** label, use a **phase**
  (or story) label for multi-phase work — e.g. a spec-kit feature uses `phase:foundational`,
  `phase:us1`, … . Labels let you group and filter (e.g. "all `phase:us1` issues in this milestone")
  **without** minting extra milestones. This is how you get per-phase visibility while keeping one
  milestone.
- **Projects = optional.** A GitHub Project is a board/table view over issues and PRs with custom
  fields and saved views. It groups *issues* (via fields/views), **not** milestones.
  - **Consider one when** you want a visual **status board** (Todo / In progress / Done) or
    roadmap/timeline; **custom fields** beyond labels (a "Phase" or "Priority" select, iteration
    dates); to **aggregate across multiple milestones or repos**; or when there are enough concurrent
    issues that the flat list is unwieldy.
  - **Skip it when** it's a small, single-repo effort tracked by one or two people — a milestone +
    labels + the issues list already answers "what's left / what's in flight", and a Project is just
    another surface that can drift out of sync. (For phase visibility specifically, a Project's
    "Phase" field and `phase:*` labels do the same job — you don't need a Project *and* per-phase
    milestones.)

## Raising an issue

A well-formed issue has:

1. **Title** — short and imperative: "Add X", "Fix Y", "Document Z".
2. **Type label** — one of:
   - `documentation` — docs, `AGENTS.md`, `README` changes
   - `enhancement` — a new capability or improvement
   - `bug` — something is broken
   - `maintenance` — chores, tooling, refactors (e.g. Makefile cleanup)
3. **Body**, using this structure:

   ```markdown
   ## Context
   Why this matters / the problem being solved.

   ## Acceptance criteria
   - [ ] What "done" looks like, as a checklist
   - [ ] ...

   ## References
   - Links to related files, issues, PRs, or docs
   ```

4. **Milestone** *(if applicable)* — assign it only when the issue is part of a larger shippable
   deliverable (see [above](#milestones-labels-and-projects)); a standalone change needs none.
5. **Grouping label** *(if applicable)* — for multi-phase work, add a `phase:*` (or story) label so
   the issue groups without a new milestone.
6. **Project** *(optional)* — add it to a board only if the effort uses one.

## Branching

Start each change in its own **git worktree**, created off a fresh `origin/main` — this avoids the
stale-base footgun (branching off an out-of-date local `main`) and lets branches run in parallel
without switching:

```sh
make worktree name=fix/typo   # fetches, then creates ../cv-fix-typo on branch fix/typo off origin/main
```

Work in the new `../cv-<name>` directory (build with `make page-container`). On your first push use
`git push -u origin <name>` — the worktree branch starts with no upstream. Remove it when done with
`git worktree remove ../cv-<name>`. Worktrees are the standard branching workflow — always branch off
`origin/main`, never a stale local `main`.

## Linking pull requests

Reference the issue in the PR description with a closing keyword so it auto-closes on merge:

```text
Closes #123
```

## Self-review before a PR

Any change over **10 reviewable lines** (excluding generated files like `package-lock.json` and
`dist/`) is self-reviewed before it's opened or reported done:

1. Run `/code-review` in Claude Code — it spawns independent reviewers that critique the diff
   (correctness, removed behavior, robustness) and verify findings.
2. Fix the confirmed findings; note anything you deliberately defer.
3. Record the review so the gate clears (the block message prints the exact command):
   `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh" record`

A `Stop` hook (`.claude/hooks/review-gate.sh`) enforces this locally for Claude Code users: it
blocks finishing a turn until the current diff is recorded as reviewed. It is a strong reminder, not
a hard gate — an ignored block eventually lets go, and it only runs for contributors using Claude
Code, so treat it as a prompt to review rather than a guarantee. Tune the threshold per-project with
`REVIEW_GATE_THRESHOLD`.

## Improving the harness

The harness — the conventions in `AGENTS.md` + the constitution, `docs/`, `.claude/`
(hooks / settings / skills), the Dev Container, CI, and the spec-kit setup — is maintained
deliberately, not ad-hoc. When a task reveals a **systemic gap** in it (a recurring footgun, a
missing convention, or an undocumented assumption):

1. **Name it** — state the gap the specific issue revealed.
2. **Propose codifying** — ask whether to fix the system (a convention / doc / tooling change)
   rather than patch the symptom once. The owner decides: codify now, defer, or skip.
3. **Track it** — if the owner agrees, raise an issue with the **`harness`** label (create it once
   if missing) plus a type label (`documentation` for convention/doc changes, `maintenance` for
   tooling/CI/Dev Container), and a body covering the recurring problem and the proposed
   codification. `harness` is a grouping **label, not a milestone** — this work is ongoing.
4. **Land it as its own change** — a focused PR separate from the task that surfaced it, keeping the
   docs and constitution in sync (`Closes #<n>`).

Examples: #68 (builds run in the Dev Container, not the host) and #70 (codifying the
in-container-builds convention) both landed; #69 (bake Dev Container installs so they persist) is
tracked.

## Doing it from the CLI (`gh`)

Create an issue:

```sh
gh issue create \
  --title "Document the build pipeline" \
  --label documentation \
  --milestone "Set up Claude Code for this repo" \
  --body "## Context
...

## Acceptance criteria
- [ ] ...
"
```

Create a milestone (no native `gh` subcommand — use the REST API):

```sh
gh api --method POST repos/{owner}/{repo}/milestones -f title="Set up Claude Code for this repo"
```

Create and attach a grouping label (for multi-phase work):

```sh
gh label create "phase:foundational" --color c5def5 --description "Feature phase"
gh issue edit 42 --add-label phase:foundational
```

List work:

```sh
gh issue list --milestone "Set up Claude Code for this repo"
gh api repos/{owner}/{repo}/milestones
```
