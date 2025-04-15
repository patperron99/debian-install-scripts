#!/bin/bash
set -uo pipefail

# Source common functions
source scripts/common_functions.sh

# Array of base packages to install
declare -a BASE_PACKAGES=(
    "python3-pip"
    "python3-venv"
    "polybar"
    "feh"
    "rofi"
    "dunst"
    "tmux"
    "build-essential"
    "cmake"
    "gettext"
    "unzip"
    "gnome-disk-utility"
    "gnome-calculator"
    "xclip"
    "flatpak"
    "thunar"
    "ripgrep"
    "psmisc"
    "npm"
    "shellcheck"
    "lxappearance"
    "lxpolkit"
    "xfce4-power-manager"
    "flameshot"
)

declare -a PICOM_DEPS=(
    "libev-dev"
    "libx11-xcb-dev"
    "libegl-dev"
    "libgl-dev"
    "libepoxy-dev"
    "libpcre2-dev"
    "libpixman-1-dev"
    "libxcb1-dev"
    "libxcb-composite0-dev"
    "libxcb-damage0-dev"
    "libxcb-glx0-dev"
    "libxcb-image0-dev"
    "libxcb-present-dev"
    "libxcb-randr0-dev"
    "libxcb-render0-dev"
    "libxcb-render-util0-dev"
    "libxcb-shape0-dev"
    "libxcb-util-dev"
    "libxcb-xfixes0-dev"
    "meson"
    "ninja-build"
    "uthash-dev"
    "libconfig-dev"
    "libdbus-1-dev"
)

# Log file for errors
LOG_FILE="/var/log/install-extras.log"

echo "Updating system..."
sudo apt update

echo "Installing extras packages..."
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

echo "Installing picom dependencies..."
for pkg in "${PICOM_DEPS[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | sudo tee -a "$LOG_FILE"
        fi
    else
        FAILED_PACKAGES+=("$pkg")
        echo "Package not found: $pkg" | sudo tee -a "$LOG_FILE"
    fi
done

echo "Installing picom-yshui (fork with blur support)..."
cd /tmp || exit
if git clone https://github.com/yshui/picom.git; then
    cd picom || exit
    meson setup --buildtype=release build
    ninja -C build
    sudo ninja -C build install
else
    echo -e "${RED}Failed to clone picom repository${NC}"
    FAILED_PACKAGES+=("picom-yshui")
    echo "Failed to clone picom repository" | sudo tee -a "$LOG_FILE"
fi

echo "Installing rofi themes ..."
cd ~ || exit
git clone --depth=1 https://github.com/adi1090x/rofi.git
cd rofi || exit
bash setup.sh

echo "Installing Flatpak and Zen browser..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
if ! sudo flatpak install -y flathub app.zen_browser.zen; then
    echo -e "${RED}Failed to install Zen browser${NC}"
    FAILED_PACKAGES+=("zen-browser-flatpak")
    echo "Failed to install Zen browser" | sudo tee -a "$LOG_FILE"
fi

echo "Installing Neovim from source..."
cd /tmp || exit
if git clone https://github.com/neovim/neovim.git; then
    cd neovim || exit
    git checkout stable
    sudo make CMAKE_BUILD_TYPE=Release
    sudo make install
else
    echo -e "${RED}Failed to clone Neovim repository${NC}"
    FAILED_PACKAGES+=("neovim")
    echo "Failed to clone Neovim repository" | sudo tee -a "$LOG_FILE"
fi

echo "Installing Nerd Fonts..."
NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts"
CLONE_DIR="/tmp/nerd-fonts"
git clone --depth 1 $NERD_FONTS_REPO $CLONE_DIR
cd $CLONE_DIR || exit
bash install.sh
cd ..
rm -rf $CLONE_DIR
echo "Nerd Fonts installation completed."

echo "Installing Dotconfigs ..."
cd ~ || exit
git clone --depth=1 https://github.com/patperron99/dotconfigs
rm .bashrc
cd dotconfigs || exit
for dir in */; do
  stow "$dir"
done

# Print installation summary
print_summary

# Save the failed packages list to a file for reference
if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages have been saved to $LOG_FILE"
fi
