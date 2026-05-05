#!/bin/bash
set -uo pipefail

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# When called from chroot-postinstall.sh, USERNAME is passed as $1
# When run standalone post-boot, defaults to the invoking user
if [ -n "${1:-}" ]; then
    INSTALL_USER="$1"
    INSTALL_HOME="/home/$1"
else
    INSTALL_USER="${SUDO_USER:-$USER}"
    INSTALL_HOME="$HOME"
fi

# Log file for errors
LOG_FILE="/var/log/hyprland-install.log"

echo -e "${GREEN}=== Hyprland Installation Script ===${NC}"
echo "Installs Hyprland and its ecosystem from Debian Testing (Forky) / Sid repositories."
echo "All packages are installed via APT — no compilation required."
echo ""

# Check Debian version
if [ -f /etc/debian_version ]; then
    DEBIAN_VERSION=$(cat /etc/debian_version)
    echo -e "${YELLOW}Detected Debian version: $DEBIAN_VERSION${NC}"
    echo ""
fi

# Packages available in Debian Testing (Forky) repositories
declare -a AVAILABLE_PACKAGES=(
    # Wayland utilities
    "waybar"
    "swaybg"
    "grim"
    "slurp"
    "wl-clipboard"

    # Notifications (Wayland-native)
    "mako-notifier"

    # App launcher (Wayland-native)
    "wofi"

    # Audio (PipeWire only)
    "pipewire"
    "pipewire-pulse"
    "pipewire-alsa"
    "wireplumber"
    "pamixer"

    # Network (iwd — no GNOME deps)
    "iwd"

    # File manager (Wayland-native) — installed without Recommends below
    # "nautilus" handled in no-recommends block

    # Disk management (lightweight, no GNOME session deps)
    "udiskie"
    "udisks2"

    # Document viewers
    "evince"
    "imv"

    # Fonts
    "fonts-noto"
    "fonts-noto-color-emoji"
    "fonts-font-awesome"
    "fonts-jetbrains-mono"

    # Terminal emulators
    "alacritty"

    # System utilities
    "brightnessctl"
    "playerctl"
    "hyprpolkitagent"

    # Qt Wayland support
    "qtwayland5"
    "qt6-wayland"

    # Display manager with Wayland support
    "sddm"

    # Media
    "mpv"
    "imagemagick"

    # System tools
    "avahi-daemon"
    # gvfs-backends and gnome-keyring handled in no-recommends block below

    # Bluetooth support (required for systemctl enable bluetooth)
    "bluez"

    # Base build tools (needed by some Hyprland tools at runtime)
    "git"
    "curl"
    "wget"
    "unzip"

    # Multi-monitor management (auto-detect profiles)
    "kanshi"

    # Screen recording (Wayland-native)
    "wf-recorder"

    # Lightweight image viewer
    "swayimg"
)

# Packages from Debian Sid (unstable) — added automatically if not in current repos
declare -a SID_PACKAGES=(
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "hyprlock"
    "hypridle"
    "hyprpicker"
    "swayosd"
    "cliphist"    # Clipboard history manager
)

echo "Updating package lists..."
_APT_CMD apt update

echo ""
echo "Installing available packages from repositories..."
echo "This may take several minutes..."
echo ""

for pkg in "${AVAILABLE_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
        FAILED_PACKAGES+=("$pkg")
        echo "Package not found: $pkg" | tee -a "$LOG_FILE"
    fi
done

# Install GNOME-originated packages without Recommends to prevent DE pollution
echo ""
echo "Installing GNOME utilities (no recommends — prevents Cinnamon/GNOME session pull)..."
for pkg in nautilus gnome-keyring gvfs-backends; do
    if check_package "$pkg"; then
        if install_package_no_recommends "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
        FAILED_PACKAGES+=("$pkg")
        echo "Package not found: $pkg" | tee -a "$LOG_FILE"
    fi
done

# Add Sid sources if any Sid package is not yet available in current repos
SID_NEEDED=false
for pkg in "${SID_PACKAGES[@]}"; do
    if ! apt-cache show "$pkg" &>/dev/null; then
        SID_NEEDED=true
        break
    fi
done

if [[ "$SID_NEEDED" == true ]]; then
    echo ""
    echo -e "${YELLOW}Some packages require Debian Sid. Adding Sid sources...${NC}"
    echo "deb http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware" \
        | tee /etc/apt/sources.list.d/sid.list > /dev/null

    # Configure APT pinning to prevent unintended upgrades from Sid
    cat << 'EOF' | tee /etc/apt/preferences.d/sid-pin > /dev/null
Package: *
Pin: release a=unstable
Pin-Priority: 100
EOF

    _APT_CMD apt update -o Dir::Etc::sourcelist="sources.list.d/sid.list" \
                    -o Dir::Etc::sourceparts="-" \
                    -o APT::Get::List-Cleanup="0"
    echo -e "${GREEN}✓ Sid sources added with pin priority 100 (explicit install only)${NC}"
fi

echo ""
echo "Installing Hyprland ecosystem packages..."
for pkg in "${SID_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Package not found: $pkg${NC}"
        FAILED_PACKAGES+=("$pkg")
        echo "Package not found: $pkg" | tee -a "$LOG_FILE"
    fi
done

echo ""
echo "Enabling essential services..."
systemctl enable iwd
systemctl enable bluetooth
systemctl enable sddm
systemctl enable avahi-daemon

echo ""
echo "Setting up Hyprland configuration directories..."
mkdir -p "$INSTALL_HOME/.config/hypr"
mkdir -p "$INSTALL_HOME/.config/waybar"
mkdir -p "$INSTALL_HOME/.config/mako"
mkdir -p "$INSTALL_HOME/.config/alacritty"
chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_HOME/.config"

# Configure iwd for network management
echo ""
echo "Configuring iwd for network management..."
mkdir -p /etc/iwd
cat << 'EOF' > /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
NameResolvingService=systemd

[Network]
EnableIPv6=true
RoutePriorityOffset=300
EOF

echo -e "${GREEN}✓ iwd configured${NC}"

# Print installation summary
print_summary

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: bash scripts/setup-hyprland-config.sh"
echo ""

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo -e "${RED}Note: Some packages failed to install. Check $LOG_FILE for details.${NC}"
fi
