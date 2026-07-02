#!/usr/bin/env bash
#
# worktree-prune.sh — remove sibling git worktrees whose PR has been merged, and
# delete their local branch. Built for the `make worktree` workflow, where each
# branch lives in its own `../cv-<name>` worktree; once its PR is squash-merged
# and the remote branch auto-deleted, the worktree and local branch linger.
#
# Usage:
#   scripts/worktree-prune.sh [--dry-run]
#
# Safe by design:
#   - never touches the main worktree, the default branch, or the current worktree;
#   - skips any worktree with uncommitted or untracked changes (never --force);
#   - prunes only when `gh` reports a MERGED PR for the branch AND the local tip is
#     provably that merged work — its HEAD equals the merged PR's head commit
#     (squash merges) or is already contained in the default branch. A branch with
#     local commits beyond the merged PR is kept, so unpushed work is never lost;
#   - without `gh` it can't verify a merge, so it prunes nothing (and says so);
#   - drops each pruned worktree's per-worktree node_modules Docker volume too
#     (like `make worktree-rm`); the shared npm cache is kept;
#   - always exits 0 — problems are warnings, never fatal — so it can safely run as
#     a best-effort step in front of `make worktree`.

set -uo pipefail

DRY_RUN=0
case "${1:-}" in
  --dry-run|-n) DRY_RUN=1 ;;
  '') ;;
  *) echo "Usage: $0 [--dry-run]" >&2; exit 0 ;;
esac

# Must be inside a git repo, else nothing to do.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Refresh remote-tracking refs and drop refs for branches deleted upstream.
git fetch --prune --quiet origin 2>/dev/null || true

# Space-safe worktree paths: strip the "worktree " prefix rather than field-split.
list_worktrees() { git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'; }

# The main worktree is the first entry; it and the current worktree are off-limits.
main_wt="$(list_worktrees | head -n1)"
current_wt="$(git rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"

# Default branch: prefer origin/HEAD, then a local main/master, else "main".
default_branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
if [ -z "$default_branch" ]; then
  if git show-ref --verify --quiet refs/heads/master && ! git show-ref --verify --quiet refs/heads/main; then
    default_branch="master"
  else
    default_branch="main"
  fi
fi

# Is `gh` usable (installed + authenticated)? It's the merge authority.
have_gh=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  have_gh=1
fi

# merged_pr_heads <branch> — echo the head-commit SHA of each MERGED PR for the
# branch (via gh). Empty when there are none or gh is unavailable.
merged_pr_heads() {
  [ "$have_gh" = 1 ] || return 0
  gh pr list --head "$1" --state merged --json headRefOid --jq '.[].headRefOid' 2>/dev/null
}

# safe_to_prune <wt> <branch> — 0 when the worktree's work is provably merged and
# nothing unique would be lost. Sets $PRUNE_REASON and returns non-zero otherwise.
PRUNE_REASON=""
safe_to_prune() {
  local wt="$1" br="$2" wt_head heads
  PRUNE_REASON=""
  if [ "$have_gh" != 1 ]; then
    PRUNE_REASON="gh unavailable — cannot verify a merged PR; install/auth gh or remove by hand"
    return 1
  fi
  heads="$(merged_pr_heads "$br")"
  if [ -z "$heads" ]; then
    PRUNE_REASON="no merged PR"
    return 1
  fi
  wt_head="$(git -C "$wt" rev-parse HEAD 2>/dev/null)" || { PRUNE_REASON="cannot resolve HEAD"; return 1; }
  # Safe when the tip is exactly what was merged (squash), or already contained in
  # the default branch (merge/rebase) — otherwise there are unmerged local commits.
  if printf '%s\n' "$heads" | grep -qxF "$wt_head" \
     || git -C "$wt" merge-base --is-ancestor HEAD "origin/$default_branch" 2>/dev/null; then
    return 0
  fi
  PRUNE_REASON="merged, but local HEAD has commits beyond the merged PR — remove by hand if intended"
  return 1
}

pruned=0 kept=0
while IFS= read -r wt; do
  [ -n "$wt" ] || continue
  [ "$wt" = "$main_wt" ] && continue
  [ "$wt" = "$current_wt" ] && continue

  # Resolve the worktree's branch; skip detached HEADs (nothing safe to key on).
  br="$(git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null)" || { echo "keep  $wt — detached HEAD"; kept=$((kept + 1)); continue; }
  [ -n "$br" ] || { kept=$((kept + 1)); continue; }
  [ "$br" = "$default_branch" ] && continue

  # Never remove work in progress: any uncommitted or untracked change blocks it.
  if [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    echo "keep  $wt ($br) — has uncommitted/untracked changes"
    kept=$((kept + 1)); continue
  fi

  if ! safe_to_prune "$wt" "$br"; then
    echo "keep  $wt ($br) — $PRUNE_REASON"
    kept=$((kept + 1)); continue
  fi

  if [ "$DRY_RUN" = 1 ]; then
    echo "prune $wt ($br) — merged [dry-run]"
    pruned=$((pruned + 1)); continue
  fi

  if git worktree remove "$wt" 2>/dev/null; then
    git branch -D "$br" >/dev/null 2>&1 || true
    # Drop the per-worktree node_modules Docker volume too (shared npm cache is
    # kept), mirroring `make worktree-rm`. Best-effort: skipped if docker is
    # absent or the volume is still in use by a running Dev Container.
    if command -v docker >/dev/null 2>&1; then
      docker volume rm "cv-node-modules-$(basename "$wt")" >/dev/null 2>&1 || true
    fi
    echo "prune $wt ($br) — merged"
    pruned=$((pruned + 1))
  else
    echo "keep  $wt ($br) — 'git worktree remove' refused (locked or dirty)"
    kept=$((kept + 1))
  fi
done < <(list_worktrees)

if [ "$DRY_RUN" = 1 ]; then
  echo "worktree-prune: would remove ${pruned}, keep ${kept} (dry-run)"
else
  echo "worktree-prune: removed ${pruned}, kept ${kept}"
fi
exit 0
