#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

SECRET_PATTERNS=(
  "\.env($|[^[:alnum:]])"
  "secrets/"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' references a secret path (matched '$pattern'). The user has prevented Bash access to .env files and secrets/." >&2
    exit 2
  fi
done

exit 0
