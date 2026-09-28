#!/usr/bin/env bash
# Plays a soft, per-session sound when Claude Code is awaiting input.
# The session_id (from the hook's stdin JSON) is hashed to pick one sound,
# so each concurrent session gets its own consistent tone. Volume is kept low.

# Toggle off by creating this flag file (see notify-sound-toggle.sh).
[ -f "$HOME/.claude/notify-sound.disabled" ] && exit 0

volume=0.04
sounds=(Tink Pop Bottle Morse Purr Glass Frog Submarine)

session_id=$(jq -r '.session_id // ""' 2>/dev/null)
hash=$(printf '%s' "$session_id" | md5 -q | cut -c1-8)
index=$(( 16#$hash % ${#sounds[@]} ))

afplay -v "$volume" "/System/Library/Sounds/${sounds[$index]}.aiff"
