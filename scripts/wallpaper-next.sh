#!/bin/bash
# wallpaper-next.sh — Cycle wallpapers for the active theme (mod+w)

THEME_STATE="$HOME/.local/share/current-theme"
WALLPAPER_BASE="$HOME/Pictures/Wallpapers"
SWAY_CONF="$HOME/.config/sway/config"

SLUG=$(cat "$THEME_STATE" 2>/dev/null || echo "gruvbox")
WALLPAPER_DIR="$WALLPAPER_BASE/$SLUG"

if [ ! -d "$WALLPAPER_DIR" ] || [ -z "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    WALLPAPER_DIR="$WALLPAPER_BASE"
fi

readarray -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

[ ${#WALLPAPERS[@]} -eq 0 ] && {
    notify-send "Wallpaper" "No wallpapers in $WALLPAPER_DIR" 2>/dev/null || true
    exit 0
}

STATE_FILE="$HOME/.local/share/wallpaper-${SLUG}.idx"
CURRENT_IDX=-1
[ -f "$STATE_FILE" ] && CURRENT_IDX=$(cat "$STATE_FILE")

NEXT_IDX=$(( (CURRENT_IDX + 1) % ${#WALLPAPERS[@]} ))
NEXT="${WALLPAPERS[$NEXT_IDX]}"
echo "$NEXT_IDX" > "$STATE_FILE"

swaymsg "output '*' bg $NEXT fill" 2>/dev/null || \
    { pkill swaybg 2>/dev/null; sleep 0.2; swaybg -i "$NEXT" -m fill & disown; }

[ -f "$SWAY_CONF" ] && sed -i "s|output \* bg .*|output * bg $NEXT fill|" "$SWAY_CONF"

notify-send "Wallpaper" "$(basename "$NEXT")" 2>/dev/null || true
