#!/usr/bin/env bash

sleep 1

# detect first connected external monitor (not eDP-1)
SECONDARY=$(hyprctl -j monitors | jq -r '.[] | select(.name != "eDP-1" and .disabled == false) | .name' | head -n1)

if [ -z "$SECONDARY" ]; then
    exit 0
fi

# move workspaces 4–10 to detected external monitor
for i in 4 5 6 7 8 9 10; do
    hyprctl dispatch moveworkspacetomonitor $i $SECONDARY
done

# ensure 1–3 stay on laptop
for i in 1 2 3; do
    hyprctl dispatch moveworkspacetomonitor $i eDP-1
done

sleep 2
