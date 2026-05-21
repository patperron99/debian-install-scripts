#!/bin/bash
# screensaver-lock.sh — Lock screen via screensaver (USR1) or directly

pgrep -x hyprlock &>/dev/null && exit 0

if pkill -USR1 -f "screensaver-tte.sh" 2>/dev/null; then
    : # tte handles lock via lock_and_cleanup
else
    hyprlock
fi
