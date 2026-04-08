#!/bin/bash
set -uo pipefail

source scripts/common_functions.sh

declare -a BASE_PACKAGES=(
    # Wayland core
    "hyprland"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "waybar"
    "swaybg"
    "swayidle"

    # Notifications
    "mako-notifier"

    # App launcher
    "wofi"

    # Screenshot (Wayland-native)
    "grim"
    "slurp"

    # Clipboard
    "wl-clipboard"

    # Terminal emulators
    "alacritty"
    "kitty"

    # Audio (PipeWire stack, no PulseAudio)
    "pipewire"
    "pipewire-pulse"
    "pipewire-alsa"
    "wireplumber"
    "pamixer"
    "pavucontrol"

    # Network
    "network-manager"
    "network-manager-gnome"

    # Bluetooth
    "blueman"

    # Display manager
    "sddm"

    # Power / backlight
    "acpid"
    "brightnessctl"

    # Media control
    "playerctl"

    # Polkit agent (Wayland-compatible)
    "policykit-1-gnome"

    # Qt Wayland support
    "qt5-wayland"
    "qt6-wayland"

    # Build tools
    "git"
    "curl"
    "wget"
    "build-essential"
    "gettext"
    "pkg-config"
    "unzip"

    # Utilities
    "ripgrep"
    "psmisc"

    # Fonts
    "fonts-noto"
    "fonts-noto-color-emoji"
    "fonts-font-awesome"
    "fonts-jetbrains-mono"
)

LOG_FILE="/var/log/postinstall-hyprland.log"

echo -e "${YELLOW}Do you want to install extras packages? (y/n)${NC}"
read -r install_extras
while [[ ! "$install_extras" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r install_extras
done

echo "Updating system..."
sudo apt update

# Add Sid sources if hyprland is not yet available in current repos
if ! apt-cache show hyprland &>/dev/null; then
    echo -e "${YELLOW}Hyprland not found in current repos. Adding Debian Sid sources...${NC}"
    echo "deb http://deb.debian.org/debian/ sid main contrib non-free non-free-firmware" \
        | sudo tee /etc/apt/sources.list.d/sid.list > /dev/null
    sudo apt update -o Dir::Etc::sourcelist="sources.list.d/sid.list" \
                    -o Dir::Etc::sourceparts="-" \
                    -o APT::Get::List-Cleanup="0"
fi

echo "Installing base packages..."
for pkg in "${BASE_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | sudo tee -a "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
        FAILED_PACKAGES+=("$pkg")
        echo "Package not found: $pkg" | sudo tee -a "$LOG_FILE"
    fi
done

# Enable services
sudo systemctl enable sddm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable acpid

# Configure SDDM for Wayland/Hyprland
sudo mkdir -p /etc/sddm.conf.d
cat << 'EOF' | sudo tee /etc/sddm.conf.d/hyprland.conf > /dev/null
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell
EOF

# Create Hyprland wayland-session entry if missing
if [ ! -f /usr/share/wayland-sessions/hyprland.desktop ]; then
    sudo mkdir -p /usr/share/wayland-sessions
    cat << 'EOF' | sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
EOF
fi

if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    echo "Installing extras packages..."
    bash scripts/install-extras-hyprland.sh
fi

print_summary

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages logged to $LOG_FILE"
fi
