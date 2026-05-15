#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

LOG_FILE="/var/log/install-extras-hyprland.log"

# When called from chroot-postinstall.sh, USERNAME is passed as $1
if [ -n "${1:-}" ]; then
    INSTALL_USER="$1"
    INSTALL_HOME="/home/$1"
else
    INSTALL_USER="${SUDO_USER:-$USER}"
    INSTALL_HOME="$HOME"
fi

declare -a EXTRA_PACKAGES=(
    # Python
    "python3-pip"
    "python3-venv"

    # System tools
    "tmux"
    "cmake"
    "meson"
    "ninja-build"
    "fwupd"
    "shellcheck"
    "npm"
    "flatpak"
    "neovim"
    "fd-find"
    "ripgrep"
    "psmisc"
    "jq"
    "fastfetch"

    # File manager
    "thunar"
    # gnome-disk-utility handled in install-hyprland.sh (replaced by udiskie)
    # gnome-calculator installed below without Recommends

    # Media
    "imv"
    "evince"
    "mpv"
    "imagemagick"

    # Avahi (gvfs-backends and gnome-keyring handled in install-hyprland.sh without Recommends)
    "avahi-daemon"

    # Power menu (Wayland-native)
    "wlogout"
)

echo -e "${GREEN}=== Extras Installation ===${NC}"
echo "Installs dev tools, fonts, Neovim, Tmux, Flatpak, and Zen browser."
echo ""

_APT_CMD apt update

echo "Installing extra packages..."
for pkg in "${EXTRA_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg"; then
            SUCCESSFUL_PACKAGES+=("$pkg")
        else
            FAILED_PACKAGES+=("$pkg")
            echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}Package not found in repository: $pkg (skipping)${NC}"
        FAILED_PACKAGES+=("$pkg")
    fi
done

# Install gnome-calculator without Recommends
if check_package "gnome-calculator"; then
    if install_package_no_recommends "gnome-calculator"; then
        SUCCESSFUL_PACKAGES+=("gnome-calculator")
    else
        FAILED_PACKAGES+=("gnome-calculator")
    fi
fi

# ─── FLATPAK: Flathub + Zen browser ───────────────────────────────────────────
echo ""
echo "Setting up Flatpak..."
# remote-add is safe in chroot (writes to /var/lib/flatpak)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
# app install requires a D-Bus user session — deferred to first login if in chroot
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || [ "$EUID" -ne 0 ]; then
    if ! flatpak install -y flathub app.zen_browser.zen 2>/dev/null; then
        echo -e "${YELLOW}Failed to install Zen browser (skipping)${NC}"
        FAILED_PACKAGES+=("zen-browser-flatpak")
    fi
else
    echo -e "${YELLOW}[DEFERRED] Zen browser Flatpak install requires a user session.${NC}"
    echo "  Run after login: flatpak install -y flathub app.zen_browser.zen"
fi

# ─── NERD FONTS ───────────────────────────────────────────────────────────────
echo ""
echo "Installing Nerd Fonts (JetBrainsMono, FiraCode, Hack)..."
NERD_FONTS_VERSION="v3.2.1"
NERD_FONTS_BASE="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}"
FONTS_DIR="$INSTALL_HOME/.local/share/fonts/NerdFonts"
mkdir -p "$FONTS_DIR"

for font in JetBrainsMono FiraCode Hack; do
    archive="/tmp/${font}.tar.xz"
    echo "  Downloading $font..."
    if curl -fsSL --connect-timeout 15 --max-time 120 \
            -o "$archive" "${NERD_FONTS_BASE}/${font}.tar.xz"; then
        tar -xf "$archive" -C "$FONTS_DIR" --wildcards '*.ttf' 2>/dev/null || \
        tar -xf "$archive" -C "$FONTS_DIR" 2>/dev/null || true
        rm -f "$archive"
        echo -e "${GREEN}  $font installed${NC}"
    else
        echo -e "${YELLOW}  Failed to download $font (skipping)${NC}"
    fi
done
chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_HOME/.local" 2>/dev/null || true
runuser -l "$INSTALL_USER" -c "fc-cache -fv '$FONTS_DIR'" >/dev/null 2>&1 || \
    fc-cache -fv "$FONTS_DIR" >/dev/null 2>&1 || true
echo -e "${GREEN}Nerd Fonts installed to $FONTS_DIR${NC}"

# ─── TMUX PLUGIN MANAGER ──────────────────────────────────────────────────────
echo ""
echo "Installing Tmux Plugin Manager (TPM)..."
TPM_DIR="$INSTALL_HOME/.config/tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    mkdir -p "$(dirname "$TPM_DIR")"
    if git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null; then
        chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_HOME/.config/tmux"
        echo -e "${GREEN}TPM installed at $TPM_DIR${NC}"
        echo "Run 'tmux' then press Prefix+I to install plugins."
    else
        echo -e "${YELLOW}Failed to clone TPM (skipping)${NC}"
    fi
else
    echo -e "${GREEN}TPM already installed${NC}"
fi

# ─── ENABLE AVAHI ─────────────────────────────────────────────────────────────
systemctl enable avahi-daemon 2>/dev/null || true

print_summary

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
    echo "Failed packages logged to $LOG_FILE"
fi
