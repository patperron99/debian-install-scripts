#!/bin/bash
set -uo pipefail

# Source common functions
source "$(dirname "$0")/common_functions.sh"

# Build directory
BUILD_DIR="$HOME/.local/src/hyprland-build"
INSTALL_PREFIX="/usr/local"

# Log file
LOG_FILE="/var/log/hyprland-compile.log"

echo -e "${GREEN}=== Hyprland Source Compilation Script ===${NC}"
echo "This script will compile Hyprland and related packages from source"
echo -e "${YELLOW}Build directory: $BUILD_DIR${NC}"
echo -e "${YELLOW}Install prefix: $INSTALL_PREFIX${NC}"
echo ""

# Create build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1

# Function to compile a CMake project
compile_cmake() {
    local repo_url=$1
    local repo_name=$2
    local cmake_opts=${3:-""}

    echo ""
    echo -e "${GREEN}Compiling $repo_name...${NC}"

    if [ -d "$repo_name" ]; then
        echo -e "${YELLOW}Directory exists, updating...${NC}"
        cd "$repo_name" || return 1
        git pull
    else
        echo "Cloning repository..."
        git clone "$repo_url" "$repo_name" || return 1
        cd "$repo_name" || return 1
    fi

    mkdir -p build
    cd build || return 1

    echo "Running cmake..."
    cmake .. -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" $cmake_opts || return 1

    echo "Building..."
    make -j"$(nproc)" || return 1

    echo "Installing..."
    sudo make install || return 1

    cd "$BUILD_DIR" || exit 1
    echo -e "${GREEN}✓ $repo_name compiled and installed${NC}"
    return 0
}

# Function to compile a Meson project
compile_meson() {
    local repo_url=$1
    local repo_name=$2
    local meson_opts=${3:-""}

    echo ""
    echo -e "${GREEN}Compiling $repo_name...${NC}"

    if [ -d "$repo_name" ]; then
        echo -e "${YELLOW}Directory exists, updating...${NC}"
        cd "$repo_name" || return 1
        git pull
    else
        echo "Cloning repository..."
        git clone "$repo_url" "$repo_name" || return 1
        cd "$repo_name" || return 1
    fi

    echo "Running meson setup..."
    meson setup build --prefix="$INSTALL_PREFIX" $meson_opts || return 1

    echo "Building..."
    ninja -C build || return 1

    echo "Installing..."
    sudo ninja -C build install || return 1

    cd "$BUILD_DIR" || exit 1
    echo -e "${GREEN}✓ $repo_name compiled and installed${NC}"
    return 0
}

# Function to compile a Go project
compile_go() {
    local repo_url=$1
    local repo_name=$2
    local binary_name=${3:-"$repo_name"}

    echo ""
    echo -e "${GREEN}Compiling $repo_name (Go)...${NC}"

    if [ -d "$repo_name" ]; then
        echo -e "${YELLOW}Directory exists, updating...${NC}"
        cd "$repo_name" || return 1
        git pull
    else
        echo "Cloning repository..."
        git clone "$repo_url" "$repo_name" || return 1
        cd "$repo_name" || return 1
    fi

    echo "Building with Go..."
    go build -o "$binary_name" || return 1

    echo "Installing..."
    sudo install -Dm755 "$binary_name" "$INSTALL_PREFIX/bin/$binary_name" || return 1

    cd "$BUILD_DIR" || exit 1
    echo -e "${GREEN}✓ $repo_name compiled and installed${NC}"
    return 0
}

# Ask user which packages to compile
echo -e "${YELLOW}Select packages to compile:${NC}"
echo "1. Hyprland (window manager)"
echo "2. hyprlock (lock screen)"
echo "3. hypridle (idle daemon)"
echo "4. hyprpaper (wallpaper manager)"
echo "5. swww (animated wallpapers)"
echo "6. cliphist (clipboard manager)"
echo "7. All of the above"
echo ""
echo -e "${YELLOW}Enter your choice (1-7):${NC}"
read -r compile_choice

while [[ ! "$compile_choice" =~ ^[1-7]$ ]]; do
    echo -e "${YELLOW}Please enter a number between 1 and 7:${NC}"
    read -r compile_choice
done

# Compile Hyprland
if [[ "$compile_choice" =~ ^[17]$ ]]; then
    echo ""
    echo -e "${GREEN}=== Compiling Hyprland ===${NC}"

    # Dependencies for Hyprland
    echo "Compiling Hyprland dependencies..."

    # hyprwayland-scanner
    compile_cmake "https://github.com/hyprwm/hyprwayland-scanner.git" "hyprwayland-scanner" || {
        echo -e "${RED}Failed to compile hyprwayland-scanner${NC}"
        FAILED_PACKAGES+=("hyprwayland-scanner")
    }

    # hyprlang
    compile_cmake "https://github.com/hyprwm/hyprlang.git" "hyprlang" || {
        echo -e "${RED}Failed to compile hyprlang${NC}"
        FAILED_PACKAGES+=("hyprlang")
    }

    # hyprutils
    compile_cmake "https://github.com/hyprwm/hyprutils.git" "hyprutils" || {
        echo -e "${RED}Failed to compile hyprutils${NC}"
        FAILED_PACKAGES+=("hyprutils")
    }

    # hyprcursor
    compile_cmake "https://github.com/hyprwm/hyprcursor.git" "hyprcursor" || {
        echo -e "${RED}Failed to compile hyprcursor${NC}"
        FAILED_PACKAGES+=("hyprcursor")
    }

    # aquamarine (Hyprland rendering backend)
    compile_cmake "https://github.com/hyprwm/aquamarine.git" "aquamarine" || {
        echo -e "${RED}Failed to compile aquamarine${NC}"
        FAILED_PACKAGES+=("aquamarine")
    }

    # Hyprland itself
    compile_cmake "https://github.com/hyprwm/Hyprland.git" "Hyprland" "-DUSE_SYSTEMD=ON" || {
        echo -e "${RED}Failed to compile Hyprland${NC}"
        FAILED_PACKAGES+=("Hyprland")
    }

    # xdg-desktop-portal-hyprland
    compile_cmake "https://github.com/hyprwm/xdg-desktop-portal-hyprland.git" "xdg-desktop-portal-hyprland" || {
        echo -e "${RED}Failed to compile xdg-desktop-portal-hyprland${NC}"
        FAILED_PACKAGES+=("xdg-desktop-portal-hyprland")
    }
fi

# Compile hyprlock
if [[ "$compile_choice" =~ ^[27]$ ]]; then
    compile_cmake "https://github.com/hyprwm/hyprlock.git" "hyprlock" || {
        echo -e "${RED}Failed to compile hyprlock${NC}"
        FAILED_PACKAGES+=("hyprlock")
    }
fi

# Compile hypridle
if [[ "$compile_choice" =~ ^[37]$ ]]; then
    compile_cmake "https://github.com/hyprwm/hypridle.git" "hypridle" || {
        echo -e "${RED}Failed to compile hypridle${NC}"
        FAILED_PACKAGES+=("hypridle")
    }
fi

# Compile hyprpaper
if [[ "$compile_choice" =~ ^[47]$ ]]; then
    compile_cmake "https://github.com/hyprwm/hyprpaper.git" "hyprpaper" || {
        echo -e "${RED}Failed to compile hyprpaper${NC}"
        FAILED_PACKAGES+=("hyprpaper")
    }
fi

# Compile swww
if [[ "$compile_choice" =~ ^[57]$ ]]; then
    echo ""
    echo -e "${GREEN}Compiling swww (Rust)...${NC}"

    # Check if Rust is installed
    if ! command -v cargo &> /dev/null; then
        echo -e "${YELLOW}Rust not found. Installing rustup...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    if [ -d "swww" ]; then
        echo -e "${YELLOW}Directory exists, updating...${NC}"
        cd swww || exit 1
        git pull
    else
        echo "Cloning repository..."
        git clone "https://github.com/LGFae/swww.git" swww || exit 1
        cd swww || exit 1
    fi

    echo "Building with Cargo..."
    cargo build --release || {
        echo -e "${RED}Failed to compile swww${NC}"
        FAILED_PACKAGES+=("swww")
        cd "$BUILD_DIR" || exit 1
    }

    if [ -f "target/release/swww" ]; then
        echo "Installing..."
        sudo install -Dm755 target/release/swww "$INSTALL_PREFIX/bin/swww"
        sudo install -Dm755 target/release/swww-daemon "$INSTALL_PREFIX/bin/swww-daemon"
        echo -e "${GREEN}✓ swww compiled and installed${NC}"
    fi

    cd "$BUILD_DIR" || exit 1
fi

# Compile cliphist
if [[ "$compile_choice" =~ ^[67]$ ]]; then
    compile_go "https://github.com/sentriz/cliphist.git" "cliphist" "cliphist" || {
        echo -e "${RED}Failed to compile cliphist${NC}"
        FAILED_PACKAGES+=("cliphist")
    }
fi

# Update dynamic linker cache
echo ""
echo "Updating linker cache..."
sudo ldconfig

echo ""
echo -e "${GREEN}=== Compilation Complete ===${NC}"
echo ""

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo -e "${RED}Failed to compile the following packages:${NC}"
    printf '%s\n' "${FAILED_PACKAGES[@]}"
    echo ""
    echo -e "${YELLOW}Check $LOG_FILE for details${NC}"
else
    echo -e "${GREEN}All packages compiled successfully!${NC}"
fi

echo ""
echo -e "${YELLOW}Compiled binaries installed to: $INSTALL_PREFIX/bin${NC}"
echo -e "${YELLOW}Libraries installed to: $INSTALL_PREFIX/lib${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run: sudo ldconfig (if not done automatically)"
echo "2. Verify installation: which Hyprland"
echo "3. Run the configuration script: bash scripts/setup-hyprland-config.sh"
echo "4. Logout and select Hyprland from your display manager"
