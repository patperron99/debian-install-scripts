#!/bin/bash
set -uo pipefail

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Log file for errors
LOG_FILE="/var/log/hyprland-install.log"

echo -e "${GREEN}=== Hyprland Installation Script ===${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT NOTES:${NC}"
echo "• Hyprland is available in Debian Sid (unstable) and Forky (testing)"
echo "• Some packages require compilation from source"
echo "• This script will install available packages from repos"
echo "• Optional: compile missing packages from source"
echo ""

# Check Debian version
if [ -f /etc/debian_version ]; then
    DEBIAN_VERSION=$(cat /etc/debian_version)
    echo -e "${YELLOW}Detected Debian version: $DEBIAN_VERSION${NC}"
    echo ""
fi

# Array of packages available in Debian Testing/Sid repositories
# Based on Omarchy's Wayland-native package selection
declare -a AVAILABLE_PACKAGES=(
    # Wayland utilities
    "waybar"
    "swaybg"
    "grim"
    "slurp"
    "wl-clipboard"

    # Notifications (Wayland-native)
    "mako-notifier"

    # Audio (PipeWire only, no GUI mixers that pull desktop deps)
    "pipewire"
    "pipewire-pulse"
    "pipewire-alsa"
    "wireplumber"
    "pamixer"

    # Network (iwd instead of NetworkManager to avoid GNOME deps)
    "iwd"

    # File manager (Wayland-native)
    "nautilus"
    "nautilus-extension-gnome-terminal"
    "gnome-disk-utility"

    # Document viewers (Wayland-capable)
    "evince"
    "imv"

    # Fonts
    "fonts-noto"
    "fonts-noto-color-emoji"
    "fonts-font-awesome"
    "fonts-jetbrains-mono"

    # Terminal emulators (Wayland-native)
    "alacritty"

    # System utilities
    "brightnessctl"
    "playerctl"
    "policykit-1-gnome"

    # Qt Wayland support
    "qt5-wayland"
    "qt6-wayland"

    # Display manager with Wayland support
    "sddm"

    # Additional Wayland tools
    "mpv"
    "imagemagick"

    # System tools (no desktop deps)
    "avahi-daemon"
    "gvfs-backends"
    "gnome-keyring"
)

# Packages available in Sid/Unstable (may need sid sources)
declare -a SID_PACKAGES=(
    "hyprland"
    "xdg-desktop-portal-hyprland"
)

# Packages that need to be compiled from source (from Omarchy ecosystem)
declare -a SOURCE_ONLY_PACKAGES=(
    "hypridle"
    "hyprlock"
    "hyprsunset"
    "hyprpicker"
    "swayosd"
)

# Build dependencies for compilation
declare -a BUILD_DEPS=(
    "build-essential"
    "cmake"
    "meson"
    "ninja-build"
    "pkg-config"
    "libwayland-dev"
    "wayland-protocols"
    "libdrm-dev"
    "libgbm-dev"
    "libinput-dev"
    "libxkbcommon-dev"
    "libsystemd-dev"
    "libpixman-1-dev"
    "libseat-dev"
    "libcairo2-dev"
    "libpango1.0-dev"
    "libjpeg-dev"
    "libwebp-dev"
    "git"
    "golang-go"
)

# Ask user about installation options
echo -e "${YELLOW}Installation options:${NC}"
echo "1. Install from Sid/Unstable repositories (recommended)"
echo "2. Compile from source (takes longer, latest versions)"
echo ""
echo -e "${YELLOW}Which option do you prefer? (1/2)${NC}"
read -r install_method

while [[ ! "$install_method" =~ ^[12]$ ]]; do
    echo -e "${YELLOW}Please enter 1 or 2:${NC}"
    read -r install_method
done

# Ask about building optional packages
COMPILE_SOURCE=false
if [[ "$install_method" == "2" ]]; then
    COMPILE_SOURCE=true
    echo -e "${YELLOW}Do you want to install build dependencies? (y/n)${NC}"
    read -r install_build_deps

    while [[ ! "$install_build_deps" =~ ^[YyNn]$ ]]; do
        echo -e "${YELLOW}Please enter y or n:${NC}"
        read -r install_build_deps
    done
fi

echo ""
echo "Updating system..."
sudo apt update

# Install build dependencies if needed
if [[ "$COMPILE_SOURCE" == true && "$install_build_deps" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Installing build dependencies..."
    for pkg in "${BUILD_DEPS[@]}"; do
        if check_package "$pkg"; then
            if install_package "$pkg"; then
                SUCCESSFUL_PACKAGES+=("$pkg")
            else
                FAILED_PACKAGES+=("$pkg")
            fi
        fi
    done
fi

echo ""
echo "Installing available packages from repositories..."
echo "This may take several minutes..."
echo ""

# Install packages available in standard repos
for pkg in "${AVAILABLE_PACKAGES[@]}"; do
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

# Handle Hyprland and related packages from Sid
if [[ "$install_method" == "1" ]]; then
    echo ""
    echo -e "${YELLOW}Installing Hyprland from Sid/Unstable...${NC}"
    echo "You may need to add Sid sources to /etc/apt/sources.list"
    echo ""

    for pkg in "${SID_PACKAGES[@]}"; do
        if check_package "$pkg"; then
            if install_package "$pkg"; then
                SUCCESSFUL_PACKAGES+=("$pkg")
            else
                FAILED_PACKAGES+=("$pkg")
                echo "Failed to install: $pkg" | sudo tee -a "$LOG_FILE"
                echo -e "${YELLOW}Tip: You may need to add Sid sources:${NC}"
                echo "deb http://deb.debian.org/debian/ sid main contrib non-free"
            fi
        else
            echo -e "${YELLOW}Package $pkg not found. Adding to compile list...${NC}"
            FAILED_PACKAGES+=("$pkg")
            echo "Package not found: $pkg - consider compiling from source" | sudo tee -a "$LOG_FILE"
        fi
    done
fi

# Compile from source if selected
if [[ "$COMPILE_SOURCE" == true ]]; then
    echo ""
    echo -e "${GREEN}=== Compiling packages from source ===${NC}"
    echo "This will take a while. Logs in: $LOG_FILE"
    echo ""

    # Call the compilation script
    if [ -f "$(dirname "$0")/compile-hyprland-sources.sh" ]; then
        bash "$(dirname "$0")/compile-hyprland-sources.sh" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}Compilation script not found!${NC}"
        echo -e "${YELLOW}Please run: bash scripts/compile-hyprland-sources.sh manually${NC}"
        echo "compile-hyprland-sources.sh not found" | sudo tee -a "$LOG_FILE"
    fi
fi

echo ""
echo "Enabling essential services..."
sudo systemctl enable iwd
sudo systemctl enable bluetooth
sudo systemctl enable sddm
sudo systemctl enable avahi-daemon

echo ""
echo "Setting up Hyprland configuration directory..."
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/mako
mkdir -p ~/.config/alacritty

# Configure iwd for network management
echo ""
echo "Configuring iwd for network management..."
sudo mkdir -p /etc/iwd
cat << 'EOF' | sudo tee /etc/iwd/main.conf > /dev/null
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
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run the configuration setup script: bash scripts/setup-hyprland-config.sh"
if [[ "$install_method" == "1" ]]; then
    echo "2. If Hyprland failed to install, add Sid sources and try again:"
    echo "   echo 'deb http://deb.debian.org/debian/ sid main' | sudo tee -a /etc/apt/sources.list.d/sid.list"
    echo "   sudo apt update && sudo apt install -t sid hyprland xdg-desktop-portal-hyprland"
fi
echo "3. Logout and select 'Hyprland' from your display manager"
echo "4. Or reboot your system"
echo ""

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo -e "${RED}Note: Some packages failed to install. Check $LOG_FILE for details${NC}"
    if [[ "$COMPILE_SOURCE" == false ]]; then
        echo -e "${YELLOW}Tip: You can compile missing packages by running:${NC}"
        echo "     bash scripts/compile-hyprland-sources.sh"
    fi
fi
