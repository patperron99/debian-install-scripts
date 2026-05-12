#!/bin/bash
# screensaver-stop.sh — Kill all screensaver instances

swaymsg '[app_id="screensaver"] kill' 2>/dev/null || true
