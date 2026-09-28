#!/usr/bin/env bash
# Turn Claude Code notification sounds on/off by toggling a flag file.
# Usage: notify-sound-toggle.sh [on|off|toggle|status]   (default: toggle)
# Takes effect immediately — no restart needed.

flag="$HOME/.claude/notify-sound.disabled"

case "${1:-toggle}" in
  on)     rm -f "$flag";  echo "Claude notification sounds: ON" ;;
  off)    touch "$flag";  echo "Claude notification sounds: OFF" ;;
  status) [ -f "$flag" ] && echo "Claude notification sounds: OFF" || echo "Claude notification sounds: ON" ;;
  toggle) if [ -f "$flag" ]; then rm -f "$flag"; echo "Claude notification sounds: ON"; else touch "$flag"; echo "Claude notification sounds: OFF"; fi ;;
  *)      echo "Usage: $(basename "$0") [on|off|toggle|status]" >&2; exit 1 ;;
esac
