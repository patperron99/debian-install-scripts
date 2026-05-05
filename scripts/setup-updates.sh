#!/bin/bash
set -uo pipefail

# setup-updates.sh — System update manager + Waybar integration
#
# Usage:
#   bash scripts/setup-updates.sh           # Interactive updater
#   bash scripts/setup-updates.sh --check   # Waybar JSON output (no sudo)

MODE="${1:-interactive}"

# --check mode: emit Waybar JSON and exit immediately (no source, no sudo)
if [[ "$MODE" == "--check" ]]; then
    COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo "0")
    SECURITY=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst.*security" || echo "0")
    if [ "$COUNT" -eq 0 ]; then
        echo '{"text":" ","tooltip":"System up to date","class":"updated"}'
    else
        echo "{\"text\":\" $COUNT\",\"tooltip\":\"$COUNT updates available ($SECURITY security)\",\"class\":\"updates-available\"}"
    fi
    exit 0
fi

# Interactive mode — source colors
source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== System Update Manager ===${NC}"
echo ""

# Refresh package lists
echo "Refreshing package lists..."
sudo apt update

# Count available updates
AVAILABLE=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo "0")
SECURITY=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst.*security" || echo "0")

echo ""
if [ "$AVAILABLE" -eq 0 ]; then
    echo -e "${GREEN}System is up to date.${NC}"
else
    echo -e "${YELLOW}Available updates: $AVAILABLE${NC}"
    if [ "$SECURITY" -gt 0 ]; then
        echo -e "${RED}  Security updates: $SECURITY${NC}"
    fi

    echo ""
    echo -e "${YELLOW}Packages to upgrade:${NC}"
    apt-get -s upgrade 2>/dev/null | grep "^Inst" | awk '{print "  " $2}'
    echo ""

    echo -e "${YELLOW}Apply all updates now? (y/n)${NC}"
    read -r apply_updates
    while [[ ! "$apply_updates" =~ ^[YyNn]$ ]]; do
        echo -e "${YELLOW}Please enter y or n:${NC}"
        read -r apply_updates
    done

    if [[ "$apply_updates" =~ ^[Yy]$ ]]; then
        sudo apt upgrade -y
        echo -e "${GREEN}Updates applied.${NC}"

        # Check if reboot is required
        if [ -f /var/run/reboot-required ]; then
            echo ""
            echo -e "${RED}⚠ REBOOT REQUIRED${NC}"
            if [ -f /var/run/reboot-required.pkgs ]; then
                echo "Packages requiring reboot:"
                cat /var/run/reboot-required.pkgs | sed 's/^/  /'
            fi
            echo ""
            echo -e "${YELLOW}Reboot now? (y/n)${NC}"
            read -r do_reboot
            while [[ ! "$do_reboot" =~ ^[YyNn]$ ]]; do
                echo -e "${YELLOW}Please enter y or n:${NC}"
                read -r do_reboot
            done
            [[ "$do_reboot" =~ ^[Yy]$ ]] && sudo reboot
        fi
    else
        echo "Updates deferred."
    fi
fi

# Offer to set up Waybar module
echo ""
echo -e "${YELLOW}Set up / reinstall the Waybar update module? (y/n)${NC}"
read -r setup_waybar
while [[ ! "$setup_waybar" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r setup_waybar
done

if [[ "$setup_waybar" =~ ^[Yy]$ ]]; then
    HELPER="$HOME/.local/bin/check-updates.sh"
    mkdir -p "$HOME/.local/bin"

    cat > "$HELPER" << 'HELPEREOF'
#!/bin/bash
COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo "0")
SECURITY=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst.*security" || echo "0")
if [ "$COUNT" -eq 0 ]; then
    echo '{"text":" ","tooltip":"System up to date","class":"updated"}'
else
    echo "{\"text\":\" $COUNT\",\"tooltip\":\"$COUNT updates available ($SECURITY security)\",\"class\":\"updates-available\"}"
fi
HELPEREOF
    chmod +x "$HELPER"
    echo -e "${GREEN}Installed: $HELPER${NC}"

    echo ""
    echo -e "${GREEN}Waybar module JSON (add to your waybar/config):${NC}"
    cat << EOF

// Add "custom/updates" to your "modules-right" array, then add this block:

"custom/updates": {
    "exec": "$HELPER",
    "return-type": "json",
    "interval": 3600,
    "format": "{}",
    "on-click": "alacritty -e bash -c 'sudo apt update && sudo apt upgrade; read -rp \\"Press Enter to close...\\"'",
    "tooltip": true
}
EOF

    echo ""
    echo -e "${GREEN}Waybar CSS (add to waybar/style.css):${NC}"
    cat << 'CSSEOF'

#custom-updates {
    padding: 0 10px;
    margin: 0 3px;
}

#custom-updates.updated {
    color: #26a65b;
}

#custom-updates.updates-available {
    color: #f39c12;
}
CSSEOF

    echo ""
    echo -e "${YELLOW}Note: If you ran setup-hyprland-config.sh, the module is already included.${NC}"
    echo "Restart Waybar to apply: killall waybar && waybar &"
fi
