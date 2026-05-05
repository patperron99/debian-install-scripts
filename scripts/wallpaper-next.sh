#!/bin/bash
# wallpaper-next.sh — Cycle to the next wallpaper in ~/Pictures/Wallpapers/
# Installed to ~/.local/bin/wallpaper-next.sh by setup-hyprland-config.sh
# Bound to SUPER+W in bindings.conf

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
AUTOSTART_CONF="$HOME/.config/hypr/autostart.conf"

shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP})
shopt -u nullglob

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Wallpaper" "No wallpapers found in $WALLPAPER_DIR" 2>/dev/null || true
    exit 0
fi

# Read current wallpaper from autostart.conf
CURRENT=""
if [ -f "$AUTOSTART_CONF" ]; then
    CURRENT=$(grep -m1 'exec-once = swaybg' "$AUTOSTART_CONF" \
        | grep -o '\-i [^ ]*' | cut -d' ' -f2)
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

# Persist to autostart.conf
if [ -f "$AUTOSTART_CONF" ]; then
    if grep -q 'exec-once = swaybg' "$AUTOSTART_CONF"; then
        sed -i "s|exec-once = swaybg.*|exec-once = swaybg -i $NEXT -m fill|" "$AUTOSTART_CONF"
    else
        printf '\n# Wallpaper\nexec-once = swaybg -i %s -m fill\n' "$NEXT" >> "$AUTOSTART_CONF"
    fi
fi

# Apply live
pkill swaybg 2>/dev/null || true
sleep 0.2
swaybg -i "$NEXT" -m fill &
disown

notify-send "Wallpaper" "$(basename "$NEXT")" 2>/dev/null || true
