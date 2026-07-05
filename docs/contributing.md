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
`git push -u origin <name>` — the worktree branch starts with no upstream. Worktrees are the standard
branching workflow — always branch off `origin/main`, never a stale local `main`.

**Cleanup is automatic.** Once a PR merges, the repo deletes its remote branch (squash-merge +
delete-branch-on-merge), leaving the worktree and local branch behind. `make worktree` prunes merged
worktrees before creating the next one, so they clear themselves in the normal loop. To prune on
demand — or remove a specific one yourself — use:

```sh
make worktree-prune                        # remove all merged worktrees (branch + node_modules volume)
bash scripts/worktree-prune.sh --dry-run   # preview what would be removed
make worktree-rm name=<name>               # remove one by hand (worktree + its node_modules volume)
```

The prune is safe: it never touches the main worktree, the current worktree, the default branch, or
any worktree with uncommitted or untracked changes. It removes a worktree only when `gh` reports a
**merged PR** for its branch *and* the local tip is provably that merged work (its HEAD matches the
merged PR's head commit, or is already in `main`) — so a branch with extra local commits beyond the
PR is kept. Without `gh` it can't verify a merge and prunes nothing. Each pruned worktree's
per-worktree `node_modules` volume is dropped too (like `make worktree-rm`); the shared npm cache is
kept.

## Linking pull requests

Reference the issue in the PR description with a closing keyword so it auto-closes on merge:

```text
Closes #123
```

When a PR resolves **several** issues (e.g. a decomposed spec-kit `T00x` task set), give **each**
one its own keyword. GitHub only applies a keyword to the **first** number that follows it, so a
comma list like `Closes #37, #38, #39` auto-closes *only* #37 and silently leaves the rest open:

```text
Closes #37, closes #38, closes #39
```

This footgun left #38–#43 (and umbrella #24) open after #67 — they had to be closed by hand.

## Self-review before a PR

Any change over **10 reviewable lines** (excluding generated files like `package-lock.json` and
`dist/`) is self-reviewed before it's opened or reported done:

1. Run `/code-review` in Claude Code — it spawns independent reviewers that critique the diff
   (correctness, removed behavior, robustness) and verify findings.
2. Fix the confirmed findings; note anything you deliberately defer.
3. Record the review so the gate clears. **Copy the exact command from the block message** rather
   than typing it — it names the worktree to record (see below):
   `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/review-gate.sh" record "<worktree>"`

A `Stop` hook (`.claude/hooks/review-gate.sh`) enforces this locally for Claude Code users: it
blocks finishing a turn until the current diff is recorded as reviewed. It is a strong reminder, not
a hard gate — an ignored block eventually lets go, and it only runs for contributors using Claude
Code, so treat it as a prompt to review rather than a guarantee. Tune the threshold per-project with
`REVIEW_GATE_THRESHOLD`.

**Worktrees.** Because work happens in a sibling worktree (`make worktree`) while the session's cwd
stays in the main checkout, the gate measures **each worktree you edited this turn** (found from the
transcript) plus the current directory's worktree, and records/clears each one **by its own root**.
So the block message's `record "<worktree>"` targets the worktree where the change lives — run it as
shown, or from inside the worktree as `bash …/review-gate.sh record`. Unrelated worktrees (another
task's WIP) are never scanned, so they can't block your turn. Only tracked changes count — a
brand-new file is measured once it's `git add`ed.

## Improving the harness

The harness — the conventions in `AGENTS.md` + the constitution, `docs/`, `.claude/`
(hooks / settings / skills), the Dev Container, CI, and the spec-kit setup — is maintained
deliberately, not ad-hoc. When a task reveals a **systemic gap** in it (a recurring footgun, a
missing convention, or an undocumented assumption):

1. **Name it** — state the gap the specific issue revealed.
2. **Propose codifying, gate first** — ask whether to fix the system rather than patch the symptom
   once. For a **costly or recurring** mistake, **prefer a deterministic gate** (a test, validation,
   lint rule, hook, or CI check that mechanically passes or fails) over a documented best practice: a
   doc relies on a fallible human or agent remembering it, a gate does not (constitution Principle VII,
   "Guardrails over guidance"). Documentation alone is never the final answer — it's a stopgap only
   when a gate is genuinely impractical, and then it ships with a filed issue to add the gate. A
   near-miss on something that matters, caught only by inspection, is itself the signal that a gate is
   missing. The owner decides: codify now, defer, or skip.
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
