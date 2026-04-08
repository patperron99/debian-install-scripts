#!/bin/bash
set -uo pipefail

source scripts/common_functions.sh

declare -a EXTRA_PACKAGES=(
    # Python
    "python3-pip"
    "python3-venv"

    # System tools
    "tmux"
    "cmake"
    "meson"
    "ninja-build"
    "stow"
    "fwupd"
    "shellcheck"
    "npm"
    "flatpak"

    # File manager + disk tools
    "nemo"
    "gnome-disk-utility"
    "gnome-calculator"

    # Image viewer (Wayland-native)
    "imv"

    # Document viewer
    "evince"

    # Video player (Wayland-native)
    "mpv"

    # Avahi / GVFS
    "avahi-daemon"
    "gvfs"
    "libsecret-1-0"

    # Misc
    "imagemagick"
    "ripgrep"
    "psmisc"
)

LOG_FILE="/var/log/install-extras-hyprland.log"

echo "Updating system..."
sudo apt update

echo "Installing extras packages..."
for pkg in "${EXTRA_PACKAGES[@]}"; do
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

# Flatpak: add Flathub and install Zen browser
echo "Setting up Flatpak..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
if ! sudo flatpak install -y flathub app.zen_browser.zen; then
    echo -e "${RED}Failed to install Zen browser${NC}"
    FAILED_PACKAGES+=("zen-browser-flatpak")
    echo "Failed to install Zen browser" | sudo tee -a "$LOG_FILE"
fi

# Neovim from source (stable branch)
echo "Installing Neovim from source..."
cd /tmp || exit 1
if git clone https://github.com/neovim/neovim.git; then
    cd neovim || exit 1
    git checkout stable
    sudo make CMAKE_BUILD_TYPE=Release
    sudo make install
    cd /tmp || exit 1
else
    echo -e "${RED}Failed to clone Neovim repository${NC}"
    FAILED_PACKAGES+=("neovim")
    echo "Failed to clone Neovim" | sudo tee -a "$LOG_FILE"
fi

# Nerd Fonts
echo "Installing Nerd Fonts..."
NERD_FONTS_DIR="/tmp/nerd-fonts"
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts "$NERD_FONTS_DIR"
cd "$NERD_FONTS_DIR" || exit 1
bash install.sh
cd /tmp || exit 1
rm -rf "$NERD_FONTS_DIR"

# Dotconfigs via stow
echo "Installing Dotconfigs..."
cd ~ || exit 1
git clone --depth=1 https://github.com/patperron99/dotconfigs
rm -f .bashrc
cd dotconfigs || exit 1
for dir in */; do
    stow "$dir"
done

# Enable avahi
sudo systemctl enable avahi-daemon

print_summary

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages logged to $LOG_FILE"
fi
