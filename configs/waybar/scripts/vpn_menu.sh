#!/bin/bash
# vpn_menu.sh — Wofi VPN manager using nmcli

VPN_LIST=$(nmcli --terse --fields NAME,TYPE connection show | grep vpn | cut -d: -f1)

MENU=$(printf '%s\n' "$VPN_LIST" "Disconnect" | grep -v "^$" | \
    wofi --dmenu --prompt "VPN:" --width 300 --height 300 --no-actions)

[ -z "$MENU" ] && exit 0

if [ "$MENU" = "Disconnect" ]; then
    nmcli connection show --active | grep vpn | awk '{print $1}' | \
        xargs -r -n1 nmcli connection down id
else
    nmcli connection up id "$MENU"
fi
