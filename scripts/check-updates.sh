#!/bin/bash
# Waybar update notification module — emits JSON for custom/updates

# Count apt updates
UPGRADES=$(apt-get -s upgrade 2>/dev/null)
APT_COUNT=$(echo "$UPGRADES" | grep -c "^Inst")
APT_SECURITY=$(echo "$UPGRADES" | grep -c "^Inst.*security")

# Count flatpak updates
FLATPAK_COUNT=0
if command -v flatpak &>/dev/null; then
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
fi

TOTAL=$((APT_COUNT + FLATPAK_COUNT))

if [ "$TOTAL" -eq 0 ]; then
    echo '{"text":"✓","tooltip":"System up to date","class":"updated"}'
else
    TOOLTIP="$APT_COUNT apt ($APT_SECURITY security)"
    [ "$FLATPAK_COUNT" -gt 0 ] && TOOLTIP="$TOOLTIP, $FLATPAK_COUNT flatpak"
    echo "{\"text\":\"↑ $TOTAL\",\"tooltip\":\"$TOOLTIP updates available\",\"class\":\"updates-available\"}"
fi
