#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Lock Screen Setup (hyprlock + hypridle) ===${NC}"
echo "Configures the lock screen and idle/sleep timers"
echo ""

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPTS_DIR/../configs" && pwd)"
CONFIG_DIR="$HOME/.config/hypr"
HYPRLOCK_CONF="$CONFIG_DIR/hyprlock.conf"
HYPRIDLE_CONF="$CONFIG_DIR/hypridle.conf"
AUTOSTART_CONF="$CONFIG_DIR/autostart.conf"

mkdir -p "$CONFIG_DIR"

# Ensure hyprlock and hypridle are installed
for pkg in hyprlock hypridle; do
    if ! command -v "$pkg" &>/dev/null; then
        echo -e "${YELLOW}$pkg not found. Installing...${NC}"
        if check_package "$pkg"; then
            if install_package "$pkg"; then
                SUCCESSFUL_PACKAGES+=("$pkg")
            else
                FAILED_PACKAGES+=("$pkg")
                echo -e "${RED}Failed to install $pkg. Ensure Sid sources are added.${NC}"
            fi
        else
            echo -e "${YELLOW}$pkg not in APT — ensure Sid sources are configured.${NC}"
            FAILED_PACKAGES+=("$pkg")
        fi
    fi
done

# Backup existing configs
for conf in "$HYPRLOCK_CONF" "$HYPRIDLE_CONF"; do
    if [ -f "$conf" ]; then
        cp "$conf" "$conf.backup"
        echo -e "${GREEN}Backed up: $(basename "$conf").backup${NC}"
    fi
done

# Install hyprlock and hypridle configs
echo ""
echo "Installing hyprlock.conf..."
cp "$CONFIGS_DIR/hypr/hyprlock.conf" "$HYPRLOCK_CONF"
echo -e "${GREEN}Installed: hyprlock.conf${NC}"

echo "Installing hypridle.conf..."
cp "$CONFIGS_DIR/hypr/hypridle.conf" "$HYPRIDLE_CONF"
echo -e "${GREEN}Installed: hypridle.conf${NC}"

# --- UPDATE AUTOSTART ---
if [ -f "$AUTOSTART_CONF" ]; then
    # Uncomment hypridle if commented out
    if grep -q "# exec-once = hypridle" "$AUTOSTART_CONF"; then
        sed -i 's|# exec-once = hypridle|exec-once = hypridle|' "$AUTOSTART_CONF"
        echo -e "${GREEN}hypridle enabled in autostart.conf${NC}"
    elif ! grep -q "exec-once = hypridle" "$AUTOSTART_CONF"; then
        printf '\n# Idle management\nexec-once = hypridle\n' >> "$AUTOSTART_CONF"
        echo -e "${GREEN}hypridle added to autostart.conf${NC}"
    else
        echo -e "${GREEN}hypridle already active in autostart.conf${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== Lock Screen Setup Complete ===${NC}"
echo ""
echo "Lock timers:"
echo "  5 min  : Dim screen to 10%"
echo "  10 min : Lock screen (hyprlock)"
echo "  15 min : Turn off display"
echo "  30 min : Suspend system"
echo ""
echo "Manual lock: SUPER+L (or run 'hyprlock')"
echo ""
echo -e "${YELLOW}Reload Hyprland config or relogin for changes to take effect.${NC}"
