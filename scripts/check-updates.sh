#!/bin/bash
# Waybar update module — emits JSON with APT + Flatpak + bluetui update counts

APT_SIMULATE=$(apt-get -s upgrade 2>/dev/null)
APT_COUNT=$(echo "$APT_SIMULATE" | grep -c "^Inst")
APT_SECURITY=$(echo "$APT_SIMULATE" | grep -c "^Inst.*security")

if command -v flatpak &>/dev/null; then
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l || echo "0")
else
    FLATPAK_COUNT=0
fi

# Check bluetui GitHub release vs installed version
BLUETUI_UPDATE=0
if command -v bluetui &>/dev/null; then
    INSTALLED=$(bluetui --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    LATEST=$(curl -s --connect-timeout 5 https://api.github.com/repos/pythops/bluetui/releases/latest \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null)
    if [ -n "$INSTALLED" ] && [ -n "$LATEST" ] && [ "$INSTALLED" != "$LATEST" ]; then
        BLUETUI_UPDATE=1
    fi
fi

TOTAL=$((APT_COUNT + FLATPAK_COUNT + BLUETUI_UPDATE))

if [ "$TOTAL" -eq 0 ]; then
    echo '{"text":"","tooltip":"System up to date","class":"updated"}'
else
    TOOLTIP="${APT_COUNT} APT"
    [ "$APT_SECURITY" -gt 0 ] && TOOLTIP+=" (${APT_SECURITY} security)"
    [ "$FLATPAK_COUNT" -gt 0 ] && TOOLTIP+=", ${FLATPAK_COUNT} Flatpak"
    [ "$BLUETUI_UPDATE" -gt 0 ] && TOOLTIP+=", 1 bluetui"
    TOOLTIP+=" updates available"
    echo "{\"text\":\"󰚰 ${TOTAL}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"updates-available\"}"
fi
