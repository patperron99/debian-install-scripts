#!/bin/bash
# Waybar update module — emits JSON with APT + Flatpak update counts

APT_SIMULATE=$(apt-get -s upgrade 2>/dev/null)
APT_COUNT=$(echo "$APT_SIMULATE" | grep -c "^Inst")
APT_SECURITY=$(echo "$APT_SIMULATE" | grep -c "^Inst.*security")

if command -v flatpak &>/dev/null; then
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l || echo "0")
else
    FLATPAK_COUNT=0
fi

TOTAL=$((APT_COUNT + FLATPAK_COUNT))

if [ "$TOTAL" -eq 0 ]; then
    echo '{"text":"","tooltip":"System up to date","class":"updated"}'
else
    TOOLTIP="${APT_COUNT} APT"
    [ "$APT_SECURITY" -gt 0 ] && TOOLTIP+=" (${APT_SECURITY} security)"
    [ "$FLATPAK_COUNT" -gt 0 ] && TOOLTIP+=", ${FLATPAK_COUNT} Flatpak"
    TOOLTIP+=" updates available"
    echo "{\"text\":\"󰚰 ${TOTAL}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"updates-available\"}"
fi
