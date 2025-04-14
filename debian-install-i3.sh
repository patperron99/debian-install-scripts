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
    "alacritty"
    "kitty"
    "git"
    "curl"
    "wget"
    "build-essential"
    "gettext"
    "pkg-config"
    "unzip"
    "network-manager"
    "network-manager-gnome"
    "blueman"
    "pulseaudio"
    "pavucontrol"
    "acpi"
    "acpid"
    "xbacklight"
    "xclip"
    "arandr"
    "lightdm"
    "slick-greeter"
    "ripgrep"
    "psmisc"
    "lxpolkit"
)


# Arrays to store failed and successful installations
declare -a FAILED_PACKAGES=()
declare -a SUCCESSFUL_PACKAGES=()

#Ask for installing extras packages with i3
echo -e "${YELLOW}Do you want to install extras packages with i3? (y/n)${NC}"
read -r install_extras

echo "Updating system..."
sudo apt update

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

# Enable necessary services
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable acpid

# Change lightdm options 
sudo sed -i 's/.*greeter-session=.*/greeter-session=slick-greeter/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*user-session=.*/user-session=i3/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*greeter-hide-users=.*/greeter-hide-users=false/' /etc/lightdm/lightdm.conf


# Install extras packages (from install-extras.sh) if user agrees.
if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    echo "Installing extras packages..."
    bash scripts/install-extras.sh
fi



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
