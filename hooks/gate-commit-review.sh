#!/bin/bash

# Pause for a diff review before any git commit, even when the commit is
# chained after other commands (e.g. `git log && ... && git commit`). A prefix
# matcher like Bash(git commit*) misses those because the command string starts
# with the earlier command; scanning the whole command string here does not.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

if echo "$COMMAND" | grep -qE 'git[[:space:]]+commit'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Auto-mode review window: check the diff in WebStorm before this commit lands."}}'
fi

exit 0
