#!/usr/bin/env bash
# Stamp a per-session "reviewed" marker when a plannotator review is launched.
# Clears the hard gate in require-plannotator-review.sh for the current diff.
# PostToolUse hook on Bash; no-op for any other command.

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')

if printf '%s' "$COMMAND" | grep -qE 'plannotator[[:space:]]+review'; then
  STATE_DIR="$HOME/.claude/state"
  mkdir -p "$STATE_DIR"
  touch "$STATE_DIR/plannotator-reviewed-$SESSION"
fi

exit 0
