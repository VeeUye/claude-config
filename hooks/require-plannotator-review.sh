#!/usr/bin/env bash
# Hard gate (PreToolUse on the subagent tool).
# Blocks @simplify / @review from running until the user has run a
# /plannotator-review since the last code edit this session.
#
# State (per session, written by the other two plannotator hooks):
#   plannotator-dirty-<session>    touched on each code edit
#   plannotator-reviewed-<session> touched when a plannotator review runs
# Allow when: no code edited since a review, or reviewed is newer than dirty.

INPUT=$(cat)
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
SUBAGENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.subagent_type // ""')

case "$SUBAGENT" in
  simplify|review) ;;
  *) exit 0 ;;
esac

STATE_DIR="$HOME/.claude/state"
DIRTY="$STATE_DIR/plannotator-dirty-$SESSION"
REVIEWED="$STATE_DIR/plannotator-reviewed-$SESSION"

# No code edited since the last review (or ever) -> allow.
[ -f "$DIRTY" ] || exit 0

# Reviewed after the most recent edit -> allow.
if [ -f "$REVIEWED" ] && [ "$REVIEWED" -nt "$DIRTY" ]; then
  exit 0
fi

# Code changed and not reviewed since -> block.
jq -nc '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Hard gate: code changed since your last /plannotator-review. Run `plannotator review --diff-type uncommitted` (or `--diff-type last-commit` after a commit) yourself via Bash with run_in_background, read its output, and address any annotations before running @simplify or @review."
  }
}'
exit 0
