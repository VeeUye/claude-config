#!/usr/bin/env bash
# Plannotator review gate + slice-size tripwire (PostToolUse Edit|Write).
#
# When a code file is written:
#   1. Stamp a per-session "dirty" marker for the hard gate
#      (require-plannotator-review.sh).
#   2. Measure the uncommitted diff (excluding api/generated + lockfiles); if it
#      is past the slice tripwire, add a "commit this slice" nudge.
#   3. Inject a reminder to pause for a scoped /plannotator-review before the
#      check/commit/fix loop.
# No-op for non-code files.
#
# Tune the tripwire with PLANNOTATOR_SLICE_THRESHOLD (default 200 lines).

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')
SESSION=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.scss) ;;
  *) exit 0 ;;
esac

STATE_DIR="$HOME/.claude/state"
mkdir -p "$STATE_DIR"
touch "$STATE_DIR/plannotator-dirty-$SESSION"

THRESHOLD="${PLANNOTATOR_SLICE_THRESHOLD:-200}"
EXCLUDE='(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)$|^api/generated/'

LINES=0
if ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  TRACKED=$(git -C "$ROOT" diff --numstat HEAD 2>/dev/null \
    | awk -v ex="$EXCLUDE" '$3 !~ ex { a=($1=="-"?0:$1); d=($2=="-"?0:$2); sum+=a+d } END { print sum+0 }')
  UNTRACKED=$(git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null \
    | grep -vE "$EXCLUDE" \
    | while IFS= read -r f; do wc -l <"$ROOT/$f" 2>/dev/null; done \
    | awk '{ sum+=$1 } END { print sum+0 }')
  LINES=$((TRACKED + UNTRACKED))
fi

WARN=""
if [ "$LINES" -gt "$THRESHOLD" ]; then
  WARN=" SLICE TRIPWIRE: the uncommitted diff is now about ${LINES} lines (excluding api/generated and lockfiles), past the ~${THRESHOLD}-line slice size. Strongly prefer committing this slice before writing more, rather than growing it into one large commit."
fi

jq -nc --arg f "$FILE" --arg warn "$WARN" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: ("This turn edited a code file (" + $f + "). Before running /check, /commit, the review/simplify/dod agents, or applying review findings as fixes, once the coherent change is green, run `plannotator review --diff-type uncommitted` yourself via the Bash tool with run_in_background (it opens the review UI and blocks until the user submits), then read its output file and address any annotations. Do not ask the user to paste the command. Keep the scoped --diff-type (bare review shows the whole branch). Proceed to checks, commits or fixes only after that review has come back approved or its annotations are addressed." + $warn)
  }
}'
