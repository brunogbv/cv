#!/usr/bin/env bash
#
# Self-review gate — a Claude Code "Stop" hook.
#
# Blocks finishing a turn when the reviewable diff (excluding generated files)
# exceeds THRESHOLD changed lines and this exact diff has not been recorded as
# reviewed. To clear it: run /code-review, address the findings, then record:
#
#     bash <this-script> record
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

# Not a git repo → nothing to gate.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# What to diff against:
#   - unborn HEAD (fresh repo, no commit yet) → staged work (--cached)
#   - otherwise → merge-base with the default branch (captures branch commits +
#     uncommitted; on the default branch this collapses to HEAD, i.e. uncommitted)
if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
  base=""
  for r in origin/HEAD origin/main origin/master main master; do
    if git rev-parse --verify --quiet "$r" >/dev/null 2>&1; then
      base="$(git merge-base HEAD "$r" 2>/dev/null)"
      break
    fi
  done
  [ -z "$base" ] && base="HEAD"
  diffbase=("$base")
else
  diffbase=(--cached)
fi

changed="$(git diff --numstat "${diffbase[@]}" -- . "${EXCLUDES[@]}" 2>/dev/null \
  | awk '{a+=$1; d+=$2} END {print a+d+0}')"
[ -z "$changed" ] && changed=0

diff_hash="$(git diff "${diffbase[@]}" -- . "${EXCLUDES[@]}" 2>/dev/null | git hash-object --stdin 2>/dev/null)"

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
key="$(printf '%s' "$root" | git hash-object --stdin 2>/dev/null | cut -c1-16)"
marker="$HOME/.claude/.review-markers/$key"

# record mode: stamp the current reviewable diff as reviewed.
if [ "${1:-}" = "record" ]; then
  mkdir -p "$HOME/.claude/.review-markers"
  printf '%s\n' "$diff_hash" > "$marker"
  echo "Recorded self-review for ${changed} reviewable line(s)."
  exit 0
fi

# Hook mode needs jq (payload parse + JSON output); without it, no-op (fail open).
command -v jq >/dev/null 2>&1 || exit 0

# Read the hook payload from stdin.
stop_active="$(cat 2>/dev/null | jq -r '.stop_hook_active // false' 2>/dev/null)"

# Already re-prompted once this stop-cycle → don't loop.
[ "$stop_active" = "true" ] && exit 0

# If this is the user-global copy and the project ships its own gate, defer to
# the project copy so we don't emit a duplicate block. Resolve the project dir
# from CLAUDE_PROJECT_DIR, falling back to the git root.
self="${BASH_SOURCE[0]}"
proj_dir="${CLAUDE_PROJECT_DIR:-$root}"
case "$self" in
  "$HOME/.claude/hooks/review-gate.sh")
    [ -n "$proj_dir" ] && [ -f "$proj_dir/.claude/hooks/review-gate.sh" ] && exit 0
    ;;
esac

# Under threshold → allow.
[ "$changed" -le "$THRESHOLD" ] 2>/dev/null && exit 0

# This exact diff already recorded as reviewed → allow.
[ -f "$marker" ] && [ "$(cat "$marker" 2>/dev/null)" = "$diff_hash" ] && exit 0

# Otherwise block and ask for a review.
reason="Self-review required before finishing: ${changed} reviewable lines changed (threshold ${THRESHOLD}) and this diff has not been reviewed. Run /code-review, address the findings, then record it:  bash \"$self\" record"
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
