#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Wallpaper Setup ===${NC}"
echo "Configures swaybg — simple Wayland wallpaper utility"
echo ""

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
SWAY_CONF="$HOME/.config/sway/config"

# Ensure swaybg is installed
if ! command -v swaybg &>/dev/null; then
    echo -e "${YELLOW}swaybg not found. Installing...${NC}"
    if check_package "swaybg"; then
        install_package "swaybg"
    else
        echo -e "${RED}swaybg not available in APT.${NC}"
        exit 1
    fi
fi

# Ensure wallpaper directory exists
mkdir -p "$WALLPAPER_DIR"

# List available wallpapers
shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP})
shopt -u nullglob

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    echo -e "${YELLOW}No wallpapers found in $WALLPAPER_DIR${NC}"
    echo ""
    echo "Add wallpaper images (.jpg, .png, .webp) to:"
    echo "  $WALLPAPER_DIR"
    echo ""
    echo "Then re-run this script."
    exit 0
fi

# Detect currently active wallpaper from sway config
CURRENT_WALLPAPER=""
if [ -f "$SWAY_CONF" ]; then
    CURRENT_WALLPAPER=$(grep -m1 'output \* bg' "$SWAY_CONF" | awk '{print $3}')
fi

# Show available wallpapers
echo "Available wallpapers in $WALLPAPER_DIR:"
echo ""
for i in "${!WALLPAPERS[@]}"; do
    label="  $((i+1))) $(basename "${WALLPAPERS[$i]}")"
    if [ "${WALLPAPERS[$i]}" = "$CURRENT_WALLPAPER" ]; then
        label+="  ${GREEN}[active]${NC}"
    fi
    echo -e "$label"
done
echo ""

echo -e "${YELLOW}Enter wallpaper number (1-${#WALLPAPERS[@]}):${NC}"
read -r selection
while ! [[ "$selection" =~ ^[0-9]+$ ]] || \
      [ "$selection" -lt 1 ] || [ "$selection" -gt "${#WALLPAPERS[@]}" ]; do
    echo -e "${YELLOW}Please enter a number between 1 and ${#WALLPAPERS[@]}:${NC}"
    read -r selection
done

SELECTED_WALLPAPER="${WALLPAPERS[$((selection-1))]}"
echo ""
echo -e "${GREEN}Selected: $(basename "$SELECTED_WALLPAPER")${NC}"

# Select display mode
echo ""
echo "Display modes:"
echo "  1) fill    — crop to fill screen (recommended)"
echo "  2) fit     — letterbox to fit screen"
echo "  3) stretch — stretch to fill (may distort)"
echo "  4) tile    — tile the image"
echo "  5) center  — center without scaling"
echo ""
echo -e "${YELLOW}Select mode (1-5, default 1):${NC}"
read -r mode_sel
case "$mode_sel" in
    2) MODE="fit" ;;
    3) MODE="stretch" ;;
    4) MODE="tile" ;;
    5) MODE="center" ;;
    *) MODE="fill" ;;
esac
echo -e "${GREEN}Mode: $MODE${NC}"

# Update sway config
if [ -f "$SWAY_CONF" ]; then
    sed -i "s|output \* bg .*|output * bg $SELECTED_WALLPAPER $MODE|" "$SWAY_CONF"
    echo -e "${GREEN}sway config updated${NC}"
fi

# Apply immediately via swaymsg (sway manages wallpaper natively via output * bg)
echo ""
if swaymsg "output '*' bg $SELECTED_WALLPAPER $MODE" 2>/dev/null; then
    echo -e "${GREEN}Wallpaper applied${NC}"
else
    echo -e "${YELLOW}No active Sway session — wallpaper takes effect on next login.${NC}"
fi

echo ""
echo -e "${GREEN}Done.${NC}"
echo "To change wallpaper: bash scripts/setup-wallpaper.sh"
echo "To add more wallpapers: copy images to $WALLPAPER_DIR"
