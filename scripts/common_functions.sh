#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Arrays to store failed and successful installations
declare -a FAILED_PACKAGES=()
declare -a SUCCESSFUL_PACKAGES=()

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

# Function to print installation summary
print_summary() {
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
}
