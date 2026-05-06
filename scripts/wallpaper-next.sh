#!/bin/bash
# wallpaper-next.sh — Cycle to the next wallpaper in ~/Pictures/Wallpapers/
# Installed to ~/.local/bin/wallpaper-next.sh by setup-sway-config.sh
# Bound to SUPER+W in sway config

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
SWAY_CONF="$HOME/.config/sway/config"

shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP})
shopt -u nullglob

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" 2>/dev/null || true
    exit 0
fi

# Read current wallpaper from sway config
CURRENT=""
if [ -f "$SWAY_CONF" ]; then
    CURRENT=$(grep -m1 'output \* bg' "$SWAY_CONF" \
        | awk '{print $3}')
fi

# Find index of current wallpaper, advance to next (circular)
CURRENT_IDX=-1
for i in "${!WALLPAPERS[@]}"; do
    if [ "${WALLPAPERS[$i]}" = "$CURRENT" ]; then
        CURRENT_IDX=$i
        break
    fi
done
NEXT_IDX=$(( (CURRENT_IDX + 1) % ${#WALLPAPERS[@]} ))
NEXT="${WALLPAPERS[$NEXT_IDX]}"

# Persist to sway config
if [ -f "$SWAY_CONF" ]; then
    sed -i "s|output \* bg .*|output * bg $NEXT fill|" "$SWAY_CONF"
fi

# Apply live
pkill swaybg 2>/dev/null || true
sleep 0.2
swaybg -i "$NEXT" -m fill &
disown

notify-send "Wallpaper" "$(basename "$NEXT")" 2>/dev/null || true
