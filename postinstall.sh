#!/bin/bash
set -uo pipefail

# Source common functions
source scripts/common_functions.sh

# Array of base packages to install
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

# Log file for errors
LOG_FILE="/var/log/postinstall.log"

# Ask for installing extras packages with i3
echo -e "${YELLOW}Do you want to install extras packages with i3? (y/n)${NC}"
read -r install_extras

# Validate user input
while [[ ! "$install_extras" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r install_extras
done

echo "Updating system..."
sudo apt update

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

# Enable necessary services
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable acpid

# Change lightdm options
sudo sed -i 's/.*greeter-session=.*/greeter-session=slick-greeter/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*user-session=.*/user-session=i3/' /etc/lightdm/lightdm.conf
sudo sed -i 's/.*greeter-hide-users=.*/greeter-hide-users=false/' /etc/lightdm/lightdm.conf

# Install extras packages if user agrees
if [[ "$install_extras" =~ ^[Yy]$ ]]; then
    echo "Installing extras packages..."
    bash scripts/install-extras.sh
fi

# Print installation summary
print_summary

# Save the failed packages list to a file for reference
if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages have been saved to $LOG_FILE"
fi
