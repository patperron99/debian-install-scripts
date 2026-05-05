#!/bin/bash
# Outputs current power profile as waybar JSON with colored icon.

PROFILE=$(powerprofilesctl get 2>/dev/null)

case "$PROFILE" in
    performance)
        ICON="󱐋"
        COLOR="#fab387"
        ;;
    balanced)
        ICON="󰓡"
        COLOR="#89b4fa"
        ;;
    power-saver)
        ICON="󰾅"
        COLOR="#a6e3a1"
        ;;
    *)
        ICON="󰛑"
        COLOR="#cdd6f4"
        ;;
esac

printf '{"text": "<span color='"'"'%s'"'"'>%s</span>", "tooltip": "%s", "class": "%s"}\n' \
    "$COLOR" "$ICON" "$PROFILE" "$PROFILE"
