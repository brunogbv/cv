# Contributing & Issue Tracking

All work on this repo is tracked in **GitHub** — Issues, Milestones, and Projects. Open an issue
before starting non-trivial work so the change is visible, reviewable, and linked to its goal.

## Where work lives

| Tool         | Purpose                                                                          |
| ------------ | -------------------------------------------------------------------------------- |
| Issues       | One unit of work — a bug, feature, doc change, or chore.                          |
| Milestones   | Group related issues that together deliver a goal (e.g. "Set up Claude Code for this repo"). |
| Projects     | Board view for status (Todo / In progress / Done).                                |

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

4. **Milestone** — assign it when the issue is part of a larger effort.
5. **Project** — add it to the board so status is tracked.

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

List work:

```sh
gh issue list --milestone "Set up Claude Code for this repo"
gh api repos/{owner}/{repo}/milestones
```
