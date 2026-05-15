#!/bin/bash
# setup-plymouth.sh — Configure Plymouth boot splash screen
# - Installs Plymouth + theme packages
# - Configures GRUB to show splash during boot
# - Updates initramfs and regenerates GRUB config

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Plymouth Boot Splash Setup ===${NC}"
echo "Configures a visual splash screen during system boot."
echo ""

# --- INSTALL PLYMOUTH & DEPENDENCIES ---
echo "Installing Plymouth and theme packages..."
_APT_CMD apt-get install -y \
    plymouth \
    plymouth-themes \
    &> /dev/null && echo -e "${GREEN}Plymouth installed${NC}" \
    || echo -e "${YELLOW}Could not install Plymouth — some dependencies may be missing${NC}"

echo ""

# --- LIST AVAILABLE THEMES ---
echo "Available Plymouth themes:"
THEMES=()
for theme_dir in /usr/share/plymouth/themes/*/; do
    theme_name=$(basename "$theme_dir")
    THEMES+=("$theme_name")
    echo "  • $theme_name"
done

echo ""

# --- PROMPT USER TO SELECT THEME ---
echo "Select a theme (enter number):"
for i in "${!THEMES[@]}"; do
    echo "  $((i+1))) ${THEMES[$i]}"
done
echo ""

read -p "Theme (1-${#THEMES[@]}): " theme_choice

if ! [[ "$theme_choice" =~ ^[0-9]+$ ]] || ((theme_choice < 1 || theme_choice > ${#THEMES[@]})); then
    echo -e "${YELLOW}Invalid choice. Skipping Plymouth theme configuration.${NC}"
    exit 0
fi

SELECTED_THEME="${THEMES[$((theme_choice - 1))]}"
echo -e "${GREEN}Selected theme: $SELECTED_THEME${NC}"
echo ""

# --- CONFIGURE THEME ---
echo "Setting Plymouth theme..."
sudo /usr/sbin/plymouth-set-default-theme "$SELECTED_THEME" \
    && echo -e "${GREEN}Theme set to: $SELECTED_THEME${NC}" \
    || echo -e "${YELLOW}Could not set theme — trying manual configuration${NC}"

# --- UPDATE GRUB CONFIGURATION ---
echo ""
echo "Configuring GRUB to show splash screen..."

# Ensure GRUB_CMDLINE_LINUX_DEFAULT includes quiet and splash
GRUB_FILE="/etc/default/grub"
if [ -f "$GRUB_FILE" ]; then
    # Check if quiet and splash are already there
    if ! grep -q "quiet.*splash\|splash.*quiet" "$GRUB_FILE"; then
        # Add quiet and splash to GRUB_CMDLINE_LINUX_DEFAULT if quiet exists
        if grep -q "GRUB_CMDLINE_LINUX_DEFAULT.*quiet" "$GRUB_FILE"; then
            sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)quiet\(".*\)/\1quiet splash\2/' "$GRUB_FILE"
        else
            # If no quiet, add both
            sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' "$GRUB_FILE"
        fi
        echo -e "${GREEN}Updated: $GRUB_FILE${NC}"
    fi
else
    echo -e "${YELLOW}$GRUB_FILE not found${NC}"
fi

# --- UPDATE INITRAMFS ---
echo ""
echo "Updating initramfs..."
if sudo update-initramfs -u -k all &> /dev/null; then
    echo -e "${GREEN}Initramfs updated${NC}"
else
    echo -e "${YELLOW}Initramfs update may have encountered issues${NC}"
fi

# --- REGENERATE GRUB CONFIG ---
echo ""
echo "Regenerating GRUB configuration..."
if sudo update-grub &> /dev/null; then
    echo -e "${GREEN}GRUB configuration updated${NC}"
else
    echo -e "${YELLOW}GRUB update may have encountered issues — run: sudo update-grub${NC}"
fi

echo ""
echo -e "${GREEN}=== Plymouth setup complete ===${NC}"
echo ""
echo "The splash screen will appear on next boot:"
echo "  • Theme: $SELECTED_THEME"
echo "  • Splash display: enabled during boot"
echo ""
echo "To change theme later: sudo /usr/sbin/plymouth-set-default-theme <theme-name>"
echo "To disable splash: remove 'splash' from GRUB_CMDLINE_LINUX_DEFAULT and run 'sudo update-grub'"
