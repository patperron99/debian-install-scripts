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
declare -a AVAILABLE_PACKAGES=(
    # Wayland core
    "xwayland"

    # Wayland utilities
    "waybar"
    "wofi"
    "dunst"
    "swaybg"
    "swaylock"
    "swayidle"
    "grim"
    "slurp"
    "wl-clipboard"

    # Audio
    "pipewire"
    "pipewire-pulse"
    "pipewire-audio"
    "wireplumber"
    "pavucontrol"

    # Network and Bluetooth
    "network-manager"
    "network-manager-gnome"
    "blueman"

    # File manager and utilities
    "thunar"
    "thunar-archive-plugin"
    "thunar-volman"
    "file-roller"

    # Fonts
    "fonts-noto"
    "fonts-noto-color-emoji"
    "fonts-font-awesome"
    "fonts-jetbrains-mono"

    # Terminal emulators
    "kitty"
    "alacritty"

    # System utilities
    "brightnessctl"
    "playerctl"
    "polkitd"
    "qt5ct"
    "kvantum"

    # Additional tools
    "rofi"
    "mako-notifier"
)

# Packages available in Sid/Unstable (may need sid sources)
declare -a SID_PACKAGES=(
    "hyprland"
    "xdg-desktop-portal-hyprland"
)

# Packages that need to be compiled from source
declare -a SOURCE_ONLY_PACKAGES=(
    "hyprpaper"
    "hypridle"
    "hyprlock"
    "swww"
    "cliphist"
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
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

echo ""
echo "Setting up Hyprland configuration directory..."
mkdir -p ~/.config/hypr
mkdir -p ~/.config/waybar
mkdir -p ~/.config/wofi
mkdir -p ~/.config/mako
mkdir -p ~/.config/kitty
mkdir -p ~/.config/alacritty

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
