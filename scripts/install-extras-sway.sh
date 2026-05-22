#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

LOG_FILE="/var/log/install-extras-sway.log"

if [ -n "${1:-}" ]; then
    INSTALL_USER="$1"
    INSTALL_HOME="/home/$1"
else
    INSTALL_USER="${SUDO_USER:-$USER}"
    INSTALL_HOME="$HOME"
fi

declare -a EXTRA_PACKAGES=(
    "pipx"
    "python3-pip"
    "python3-venv"
    "tmux"
    "cmake"
    "meson"
    "ninja-build"
    "fwupd"
    "shellcheck"
    "npm"
    "fd-find"
    "ripgrep"
    "psmisc"
    "jq"
    "fastfetch"
    # file manager + preview deps
    "bat"
    "ffmpegthumbnailer"
    "poppler-utils"
    "unar"
    "imagemagick"
    "libimage-exiftool-perl"
    "zoxide"
    "chafa"
)

echo -e "${GREEN}=== Extras Installation ===${NC}"
echo "Installs dev tools, fonts, Neovim, Tmux, and bluetui TUI Bluetooth manager."
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

echo ""
echo "Installing packages from testing (version conflicts with stable)..."
setup_testing_sources
apt-get install -y -t testing neovim file
echo -e "${GREEN}✓ neovim, file installed from testing${NC}"

if check_package "gnome-calculator"; then
    if install_package_no_recommends "gnome-calculator"; then
        SUCCESSFUL_PACKAGES+=("gnome-calculator")
    else
        FAILED_PACKAGES+=("gnome-calculator")
    fi
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

# ─── GITHUB BINARIES (bluetui, impala, yazi, spf) ────────────────────────────
echo ""
echo "Installing GitHub binaries..."
bash "$(dirname "$0")/install-github-bins.sh" --user "$INSTALL_USER"

# ─── PRITUNL CLIENT: VPN (GitHub .deb for Trixie) ────────────────────────────
echo ""
echo "Installing pritunl-client (VPN)..."
PRITUNL_DEB=$(curl -sL https://api.github.com/repos/pritunl/pritunl-client-electron/releases/latest \
    | python3 -c "
import sys, json
r = json.load(sys.stdin)
url = next((a['browser_download_url'] for a in r['assets']
            if 'pritunl-client_' in a['name'] and 'trixie_amd64.deb' in a['name']), '')
print(url)
" 2>/dev/null)

if [ -n "$PRITUNL_DEB" ]; then
    TMP_DEB=$(mktemp /tmp/pritunl-client-XXXXXX.deb)
    if curl -fsSL --connect-timeout 15 --max-time 120 -o "$TMP_DEB" "$PRITUNL_DEB" 2>/dev/null; then
        if dpkg -i "$TMP_DEB" 2>/dev/null; then
            echo -e "${GREEN}✓ pritunl-client installed${NC}"
        else
            apt-get install -f -y 2>/dev/null || true
            echo -e "${GREEN}✓ pritunl-client installed (with dependency fix)${NC}"
        fi
    else
        echo -e "${YELLOW}Could not download pritunl-client (optional)${NC}"
    fi
    rm -f "$TMP_DEB"
else
    echo -e "${YELLOW}Could not fetch pritunl-client release URL (optional)${NC}"
fi

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
