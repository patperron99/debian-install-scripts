#!/bin/bash
# Wofi menu to select a power profile via powerprofilesctl.

CURRENT=$(powerprofilesctl get 2>/dev/null)

CHOICE=$(printf '󱐋  performance\n󰓡  balanced\n󰾅  power-saver' | \
    wofi --dmenu --prompt "Power Profile  [${CURRENT}]:" \
         --width 260 --height 145 --no-actions)

[ -z "$CHOICE" ] && exit 0

PROFILE=$(echo "$CHOICE" | awk '{print $NF}')
powerprofilesctl set "$PROFILE" && \
    notify-send "Power Profile" "Switched to $PROFILE"
