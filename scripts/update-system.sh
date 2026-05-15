#!/bin/bash
# update-system.sh — Interactive system updater (apt + flatpak + optional BTRFS snapshot)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== System Update ===${NC}"
echo ""

# --- APT ---
echo "Refreshing package lists..."
sudo apt update

echo ""
APT_COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst")
if [ "$APT_COUNT" -eq 0 ]; then
    echo -e "${GREEN}No apt updates available.${NC}"
else
    echo -e "${YELLOW}$APT_COUNT apt package(s) to upgrade.${NC}"
    echo ""
    sudo apt upgrade -y
    echo -e "${GREEN}APT upgrade complete.${NC}"
fi

# --- Flatpak ---
if command -v flatpak &>/dev/null; then
    echo ""
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    if [ "$FLATPAK_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No Flatpak updates available.${NC}"
    else
        echo -e "${YELLOW}$FLATPAK_COUNT Flatpak application(s) to update.${NC}"
        echo ""
        flatpak update -y
        echo -e "${GREEN}Flatpak update complete.${NC}"
    fi
fi

# --- Reboot check ---
if [ -f /var/run/reboot-required ]; then
    echo ""
    echo -e "${RED}⚠  REBOOT REQUIRED${NC}"
    if [ -f /var/run/reboot-required.pkgs ]; then
        echo "Packages requiring reboot:"
        sed 's/^/  /' /var/run/reboot-required.pkgs
    fi
    echo ""
    echo -e "${YELLOW}Reboot now? (y/n)${NC}"
    read -r do_reboot
    [[ "$do_reboot" =~ ^[Yy]$ ]] && sudo reboot
fi

pkill -RTMIN+8 waybar 2>/dev/null || true

echo ""
read -rp "Press Enter to close..."
