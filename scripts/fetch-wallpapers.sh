#!/bin/bash
# fetch-wallpapers.sh — Download curated free wallpapers to ~/Pictures/Wallpapers/
# Sources: Unsplash (free to use) via direct stable URLs

set -uo pipefail

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Curated wallpapers — dark/moody aesthetics fitting a tiling WM
# Format: "filename|url"
declare -a WALLPAPERS=(
    "mountain-dark.jpg|https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=2560&q=85&fm=jpg"
    "forest-mist.jpg|https://images.unsplash.com/photo-1448375240586-882707db888b?w=2560&q=85&fm=jpg"
    "ocean-cliff.jpg|https://images.unsplash.com/photo-1505118380757-91f5f5632de0?w=2560&q=85&fm=jpg"
    "desert-dunes.jpg|https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=2560&q=85&fm=jpg"
    "northern-lights.jpg|https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=2560&q=85&fm=jpg"
    "city-night.jpg|https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=2560&q=85&fm=jpg"
    "abstract-dark.jpg|https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=2560&q=85&fm=jpg"
    "volcanic-lava.jpg|https://images.unsplash.com/photo-1497366216548-37526070297c?w=2560&q=85&fm=jpg"
)

echo -e "${GREEN}=== Wallpaper Fetcher ===${NC}"
echo "Destination: $WALLPAPER_DIR"
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

for entry in "${WALLPAPERS[@]}"; do
    FILENAME="${entry%%|*}"
    URL="${entry##*|}"
    DEST="$WALLPAPER_DIR/$FILENAME"

    if [ -f "$DEST" ]; then
        echo -e "  ${YELLOW}SKIP${NC}  $FILENAME (already exists)"
        ((SKIPPED++))
        continue
    fi

    printf "  Downloading %s ... " "$FILENAME"
    if curl -fsSL --connect-timeout 10 --max-time 60 -o "$DEST" "$URL" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        ((DOWNLOADED++))
    else
        echo -e "${RED}FAIL${NC}"
        rm -f "$DEST"
        ((FAILED++))
    fi
done

echo ""
echo -e "${GREEN}Done.${NC} Downloaded: $DOWNLOADED  Skipped: $SKIPPED  Failed: $FAILED"
echo "Wallpapers stored in: $WALLPAPER_DIR"

# ── Theme-specific wallpapers ─────────────────────────────────────────────────
THEME_DIR="$WALLPAPER_DIR/themes"
mkdir -p "$THEME_DIR"

echo ""
echo "Downloading theme-specific wallpapers to $THEME_DIR ..."

declare -a THEME_WALLPAPERS=(
    "catppuccin-mocha.jpg|https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=2560&q=85&fm=jpg"
    "tokyo-night.jpg|https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?w=2560&q=85&fm=jpg"
    "gruvbox-dark.jpg|https://images.unsplash.com/photo-1509316785289-025f5b846b35?w=2560&q=85&fm=jpg"
    "nord.jpg|https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=2560&q=85&fm=jpg"
    "rose-pine.jpg|https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=2560&q=85&fm=jpg"
)

THEME_DOWNLOADED=0
THEME_SKIPPED=0
THEME_FAILED=0

for entry in "${THEME_WALLPAPERS[@]}"; do
    FILENAME="${entry%%|*}"
    URL="${entry##*|}"
    DEST="$THEME_DIR/$FILENAME"

    if [ -f "$DEST" ]; then
        echo -e "  ${YELLOW}SKIP${NC}  $FILENAME (already exists)"
        ((THEME_SKIPPED++))
        continue
    fi

    printf "  Downloading %s ... " "$FILENAME"
    if curl -fsSL --connect-timeout 10 --max-time 60 -o "$DEST" "$URL" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        ((THEME_DOWNLOADED++))
    else
        echo -e "${RED}FAIL${NC}"
        rm -f "$DEST"
        ((THEME_FAILED++))
    fi
done

echo -e "${GREEN}Done.${NC} Downloaded: $THEME_DOWNLOADED  Skipped: $THEME_SKIPPED  Failed: $THEME_FAILED"
echo "Theme wallpapers stored in: $THEME_DIR"
echo ""
echo "Use 'bash scripts/setup-wallpaper.sh' to select one interactively,"
echo "or press SUPER+W in Sway to cycle through them."
echo "Press SUPER+SHIFT+T to switch themes (wallpaper changes automatically)."
