#!/bin/bash
# refresh-workspaces.sh — Détecte les moniteurs connectés et régénère workspaces.conf
# Installed to ~/.local/bin/refresh-workspaces.sh by setup-sway-config.sh

WORKSPACES_CONF="$HOME/.config/sway/workspaces.conf"
PRIMARY="eDP-1"

if command -v jq &>/dev/null; then
    mapfile -t OUTPUTS < <(swaymsg -t get_outputs 2>/dev/null | jq -r '.[].name')
else
    mapfile -t OUTPUTS < <(swaymsg -t get_outputs 2>/dev/null | grep -o '"name":"[^"]*' | cut -d'"' -f4)
fi

SECONDARY=""
for output in "${OUTPUTS[@]}"; do
    [[ "$output" != "$PRIMARY" ]] && { SECONDARY="$output"; break; }
done

{
    if [[ -n "$SECONDARY" ]]; then
        for i in 1 2 3 4 5; do
            echo "workspace $i output $PRIMARY"
        done
        for i in 6 7 8 9 10; do
            echo "workspace $i output $SECONDARY"
        done
    else
        for i in 1 2 3 4 5 6 7 8 9 10; do
            echo "workspace $i output $PRIMARY"
        done
    fi
} > "$WORKSPACES_CONF"

swaymsg reload

if [[ -n "$SECONDARY" ]]; then
    notify-send "Workspaces" "Dual monitor: 1–5 → $PRIMARY, 6–10 → $SECONDARY"
else
    notify-send "Workspaces" "Single monitor: 1–10 → $PRIMARY"
fi
