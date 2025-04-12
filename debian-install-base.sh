#!/bin/bash
set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


# Function to check if a package exists in apt repository
check_package() {
    sudo apt-cache show "$1" &> /dev/null
    return $?
}

# Function to install a package with error handling
install_package() {
    local pkg=$1
    if sudo apt-get install -y "$pkg" &> /dev/null; then
        echo -e "${GREEN}Successfully installed: $pkg${NC}"
        return 0
    else
        echo -e "${RED}Failed to install: $pkg${NC}"
        return 1
    fi
}

# Array of base packages to install
# Edit this array to add or remove packages
declare -a BASE_PACKAGES=(
    "i3-wm"
    "polybar"
    "rofi"
    "dunst"
    "alacritty"
    "kitty"
    "tmux"
    "stow"
    "git"
    "curl"
    "wget"
    "build-essential"
    "cmake"
    "gettext"
    "pkg-config"
    "unzip"
    "python3-pip"
    "python3-venv"
    "network-manager"
    "network-manager-gnome"
    "gnome-disk-utility"
    "gnome-calculator"
    "blueman"
    "pulseaudio"
    "pavucontrol"
    "acpi"
    "acpid"
    "xbacklight"
    "xclip"
    "feh"
    "arandr"
    "flatpak"
    "lightdm"
    "slick-greeter"
    "thunar"
    "ripgrep"
    "psmisc"
    "npm"
    "shellcheck"
    "lxappearance"
    "lxpolkit"
    "xfce4-power-manager"
    "fwupd"
)

declare -a PICOM_DEPS=(
    "libev-dev"
    "libx11-xcb-dev"
    "libegl-dev"
    "libgl-dev"
    "libepoxy-dev"
    "libpcre2-dev"
    "libpixman-1-dev"
    "libx11-xcb-dev"
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
    "libconfig-doc"
    "libconfig9"
    "libdbus-1-dev"
)

# Arrays to store failed and successful installations
declare -a FAILED_PACKAGES=()
declare -a SUCCESSFUL_PACKAGES=()

echo "Setting up Debian repositories..."

# Add non-free and contrib repositories
sudo cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
EOF

echo "Updating system..."
sudo apt-get update

echo "Installing base packages..."
for pkg in "${BASE_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
        fi
    else
        echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
        FAILED_PACKAGES+=("$pkg")
    fi
done

echo "Installing picom dependencies..."
for pkg in "${PICOM_DEPS[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
        fi
    else
        FAILED_PACKAGES+=("$pkg")
    fi
done

echo "Installing picom-yshui (fork with blur support)..."
cd /tmp || exit
if git clone https://github.com/yshui/picom.git; then
    cd picom || exit
    meson setup --buildtype=release build
    ninja -C build
    ninja -C build install
else
    echo -e "${RED}Failed to clone picom repository${NC}"
    FAILED_PACKAGES+=("picom-yshui")
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
fi

echo "Installing Nerd Fonts..."
# URL for Nerd Fonts repository
NERD_FONTS_REPO="https://github.com/ryanoasis/nerd-fonts"
# Directory to clone the repository
CLONE_DIR="/tmp/nerd-fonts"
# Clone the repository
git clone --depth 1 $NERD_FONTS_REPO $CLONE_DIR
cd $CLONE_DIR || exit
bash install.sh
# Clean up
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

# Enable necessary services
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable acpid

# Change lightdm options 
sudo sed -i 's/.*greeter-session=.*/greeter-session=slick-greeter/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*user-session=.*/user-session=i3/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*greeter-hide-users=.*/greeter-hide-users=false/' /etc/lightdm/lightdm.conf

# Print installation summary
echo -e "\n${GREEN}Installation Summary:${NC}"
echo -e "\n${GREEN}Successfully installed packages:${NC}"
printf '%s\n' "${SUCCESSFUL_PACKAGES[@]}"

echo -e "\n${RED}Failed installations:${NC}"
if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
    echo "None"
else
    printf '%s\n' "${FAILED_PACKAGES[@]}"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Reboot your system"
echo "2. Configure your desktop environment settings from scratch or from your Dotfiles"

# Save the failed packages list to a file for reference
if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages have been saved to /root/failed_packages.txt"
    printf '%s\n' "${FAILED_PACKAGES[@]}" > /root/failed_packages.txt
fi
