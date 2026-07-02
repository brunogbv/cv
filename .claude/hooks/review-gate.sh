#!/usr/bin/env bash
#
# Self-review gate — a Claude Code "Stop" hook.
#
# Blocks finishing a turn when the reviewable diff (excluding generated files)
# exceeds THRESHOLD changed lines and this exact diff has not been recorded as
# reviewed. To clear it, run /code-review, address the findings, then record the
# diff. The block message prints the exact command, which is one of:
#
#     bash <this-script> record          # records the current directory's worktree
#     bash <this-script> record <dir>    # records the worktree containing <dir>
#
# Worktrees: with the `make worktree` workflow, edits land in a sibling worktree
# (../cv-<name>) while the session's cwd stays in the main checkout — which then
# has no diff. So the gate measures every worktree this session edited
# (discovered from the transcript's file-editing tool calls) plus the current
# directory's worktree, and records/clears each worktree independently by its
# own root. It does NOT scan unrelated worktrees, so another session's WIP can't
# block this turn.
#
# Threshold is 10 by default; override per-project with REVIEW_GATE_THRESHOLD
# (non-integer values are ignored). Requires git and jq; without either the gate
# no-ops (fails open) rather than wedging a turn.
#
# NOTE: as a Stop hook this is a strong *nudge*, not an ironclad gate — an agent
# that ignores the block and stops again is let through (the stop_hook_active
# loop guard). CI is the enforcement layer for changes that must not merge
# unreviewed.

THRESHOLD="${REVIEW_GATE_THRESHOLD:-10}"
case "$THRESHOLD" in ''|*[!0-9]*) THRESHOLD=10 ;; esac

# Generated / vendored paths that should neither count toward the threshold nor
# need human-style review.
EXCLUDES=(
  ':(exclude)package-lock.json'   ':(exclude)**/package-lock.json'
  ':(exclude)yarn.lock'           ':(exclude)**/yarn.lock'
  ':(exclude)pnpm-lock.yaml'      ':(exclude)**/pnpm-lock.yaml'
  ':(exclude)poetry.lock'         ':(exclude)Cargo.lock'
  ':(exclude)go.sum'              ':(exclude)composer.lock'
  ':(exclude)dist/**'             ':(exclude)build/**'
  ':(exclude)**/*.min.js'         ':(exclude)**/*.min.css'
)

# reviewable_for <dir> — for the git worktree containing <dir>, set globals
# RG_CHANGED (reviewable changed-line count), RG_HASH (diff hash) and RG_ROOT
# (worktree root). Returns non-zero if <dir> is not inside a work tree.
#
# What it diffs against, per worktree:
#   - unborn HEAD (fresh repo, no commit yet) → staged work (--cached)
#   - otherwise → merge-base with the default branch (captures branch commits +
#     uncommitted; on the default branch this collapses to HEAD, i.e. uncommitted)
reviewable_for() {
  local dir="$1" base r diffbase
  RG_CHANGED=0; RG_HASH=""; RG_ROOT=""
  RG_ROOT="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return 1
  [ -n "$RG_ROOT" ] || return 1
  if git -C "$RG_ROOT" rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
    base=""
    for r in origin/HEAD origin/main origin/master main master; do
      if git -C "$RG_ROOT" rev-parse --verify --quiet "$r" >/dev/null 2>&1; then
        base="$(git -C "$RG_ROOT" merge-base HEAD "$r" 2>/dev/null)"
        break
      fi
    done
    [ -z "$base" ] && base="HEAD"
    diffbase="$base"
  else
    diffbase="--cached"
  fi
  RG_CHANGED="$(git -C "$RG_ROOT" diff --numstat "$diffbase" -- . "${EXCLUDES[@]}" 2>/dev/null \
    | awk '{a+=$1; d+=$2} END {print a+d+0}')"
  [ -z "$RG_CHANGED" ] && RG_CHANGED=0
  RG_HASH="$(git -C "$RG_ROOT" diff "$diffbase" -- . "${EXCLUDES[@]}" 2>/dev/null | git hash-object --stdin 2>/dev/null)"
  return 0
}

# marker_for <root> — echoes the marker file path for a worktree root. Keyed by
# the root path so each worktree records/clears independently.
marker_for() {
  local key
  key="$(printf '%s' "$1" | git hash-object --stdin 2>/dev/null | cut -c1-16)"
  printf '%s/.claude/.review-markers/%s' "$HOME" "$key"
}

# record mode: stamp a worktree's current reviewable diff as reviewed.
#   record        → the current directory's worktree
#   record <dir>  → the worktree containing <dir>
# Runs before the cwd git-repo check below so it still works when invoked from a
# non-repo cwd against a worktree path — it validates its own target instead.
if [ "${1:-}" = "record" ]; then
  target="${2:-$PWD}"
  if ! reviewable_for "$target"; then
    echo "Not inside a git worktree: $target" >&2
    exit 0
  fi
  mkdir -p "$HOME/.claude/.review-markers"
  if ! printf '%s\n' "$RG_HASH" > "$(marker_for "$RG_ROOT")"; then
    echo "Failed to write review marker under $HOME/.claude/.review-markers" >&2
    exit 0
  fi
  echo "Recorded self-review for ${RG_CHANGED} reviewable line(s) in ${RG_ROOT}."
  exit 0
fi

# Not a git repo (from cwd) → nothing to gate.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Hook mode needs jq (payload parse + JSON output); without it, no-op (fail open).
command -v jq >/dev/null 2>&1 || exit 0

# Read the hook payload from stdin.
payload="$(cat 2>/dev/null)"
stop_active="$(printf '%s' "$payload" | jq -r '.stop_hook_active // false' 2>/dev/null)"

# Already re-prompted once this stop-cycle → don't loop.
[ "$stop_active" = "true" ] && exit 0

# If this is the user-global copy and the project ships its own gate, defer to
# the project copy so we don't emit a duplicate block. Resolve the project dir
# from CLAUDE_PROJECT_DIR, falling back to the git root.
self="${BASH_SOURCE[0]}"
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
proj_dir="${CLAUDE_PROJECT_DIR:-$root}"
case "$self" in
  "$HOME/.claude/hooks/review-gate.sh")
    [ -n "$proj_dir" ] && [ -f "$proj_dir/.claude/hooks/review-gate.sh" ] && exit 0
    ;;
esac

# Build the set of worktrees to gate: the current directory's worktree, plus the
# worktree of every file edited this session (read from the transcript). This
# covers the git-worktree workflow, where edits land in a sibling worktree while
# cwd stays in the main checkout.
TARGETS=()
add_target() {
  local r="$1" t
  [ -n "$r" ] || return
  for t in "${TARGETS[@]}"; do [ "$t" = "$r" ] && return; done
  TARGETS+=("$r")
}

add_target "$root"

transcript_path="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null)"
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$p" in /*) ;; *) continue ;; esac   # tool file paths are absolute; skip anything else
    r="$(git -C "$(dirname "$p")" rev-parse --show-toplevel 2>/dev/null)"
    add_target "$r"
  done < <(jq -rR 'fromjson? | .message.content[]?
                     | select(.type? == "tool_use")
                     | select((.name? // "") | test("^(Edit|Write|MultiEdit|NotebookEdit)$"))
                     | (.input.file_path // .input.notebook_path // empty)' \
             "$transcript_path" 2>/dev/null | sort -u)
fi

# Collect worktrees whose reviewable diff exceeds the threshold and whose current
# diff has not been recorded as reviewed.
blocks=""
for wt in "${TARGETS[@]}"; do
  reviewable_for "$wt" || continue
  [ "$RG_CHANGED" -le "$THRESHOLD" ] 2>/dev/null && continue
  m="$(marker_for "$RG_ROOT")"
  [ -f "$m" ] && [ "$(cat "$m" 2>/dev/null)" = "$RG_HASH" ] && continue
  blocks+="  - ${RG_CHANGED} reviewable lines in ${RG_ROOT}"$'\n'
  blocks+="      record after review:  bash \"$self\" record \"$RG_ROOT\""$'\n'
done

# Nothing over threshold and unreviewed → allow.
[ -z "$blocks" ] && exit 0

reason="Self-review required before finishing. Unreviewed changes over the threshold (${THRESHOLD} lines):
${blocks}Run /code-review, address the findings, then record each worktree with the command shown above."
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
