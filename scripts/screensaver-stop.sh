#!/bin/bash
# screensaver-stop.sh — Lock if not already locked, then kill all screensaver instances

pgrep -x hyprlock &>/dev/null || swaymsg exec -- hyprlock
swaymsg '[app_id="screensaver"] kill' 2>/dev/null || true
