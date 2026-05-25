#!/bin/bash
# utilitymenu.sh — Menu utilitaire via wofi dmenu
# Installed to ~/.local/bin/utilitymenu.sh by setup-sway-config.sh
# Bound to Super+Escape in configs/sway/keybindings.conf

CHOICE=$(printf 'Power\nUpdate\nPower Profile\nRefresh Workspace' | \
    wofi --dmenu --prompt "Menu" --width 240 --height 195 --no-actions --insensitive)

case "$CHOICE" in
    Power)
        bash ~/.local/bin/powermenu.sh
        ;;
    Update)
        kitty -e bash ~/.local/bin/update-system.sh
        ;;
    "Power Profile")
        CURRENT=$(powerprofilesctl get 2>/dev/null)
        PROFILE=$(printf '󱐋  performance\n󰓡  balanced\n󰾅  power-saver' | \
            wofi --dmenu --prompt "Power Profile  [${CURRENT}]:" \
                 --width 260 --height 145 --no-actions)
        [ -z "$PROFILE" ] && exit 0
        PROFILE=$(echo "$PROFILE" | awk '{print $NF}')
        powerprofilesctl set "$PROFILE" && \
            notify-send "Power Profile" "Switched to $PROFILE" && \
            pkill -RTMIN+9 waybar
        ;;
    "Refresh Workspace")
        bash ~/.local/bin/refresh-workspaces.sh
        ;;
esac
