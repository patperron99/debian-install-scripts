#!/bin/bash
# wallpaper-next.sh — Cycle to the next wallpaper in ~/Pictures/Wallpapers/

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
STATE_FILE="$HOME/.local/share/wallpaper-next.idx"
SWAY_CONF="$HOME/.config/sway/config"

readarray -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" 2>/dev/null || true
    exit 0
fi

CURRENT_IDX=-1
if [ -f "$STATE_FILE" ]; then
    CURRENT_IDX=$(cat "$STATE_FILE")
fi

NEXT_IDX=$(( (CURRENT_IDX + 1) % ${#WALLPAPERS[@]} ))
NEXT="${WALLPAPERS[$NEXT_IDX]}"

echo "$NEXT_IDX" > "$STATE_FILE"

swaymsg "output '*' bg $NEXT fill" 2>/dev/null || \
    { pkill swaybg 2>/dev/null; sleep 0.2; swaybg -i "$NEXT" -m fill & disown; }

if [ -f "$SWAY_CONF" ]; then
    sed -i "s|output \* bg .*|output * bg $NEXT fill|" "$SWAY_CONF"
fi

notify-send "Wallpaper" "$(basename "$NEXT")" 2>/dev/null || true
