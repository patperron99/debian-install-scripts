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
echo "Installing neovim from testing (stable version is too old for LazyVim)..."
setup_testing_sources
apt-get install -y -t testing neovim
echo -e "${GREEN}✓ neovim installed from testing${NC}"

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
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
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

# ─── BLUETUI: TUI Bluetooth Manager (GitHub binary) ───────────────────────────
echo ""
echo "Installing bluetui (TUI Bluetooth manager)..."
BLUETUI_BIN="$INSTALL_HOME/.local/bin/bluetui"
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  BLUETUI_ASSET="bluetui-x86_64-linux-musl" ;;
    aarch64) BLUETUI_ASSET="bluetui-aarch64-linux-musl" ;;
    *)       BLUETUI_ASSET="" ;;
esac

if [ -z "$BLUETUI_ASSET" ]; then
    echo -e "${YELLOW}bluetui: unsupported architecture ($ARCH) — skipped${NC}"
else
    BLUETUI_URL=$(curl -s https://api.github.com/repos/pythops/bluetui/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$BLUETUI_ASSET'))" 2>/dev/null)
    if [ -n "$BLUETUI_URL" ]; then
        mkdir -p "$INSTALL_HOME/.local/bin"
        if curl -fsSL --connect-timeout 15 --max-time 60 -o "$BLUETUI_BIN" "$BLUETUI_URL" 2>/dev/null; then
            chmod +x "$BLUETUI_BIN"
            chown "$INSTALL_USER:$INSTALL_USER" "$BLUETUI_BIN"
            echo -e "${GREEN}✓ bluetui installed${NC}"
        else
            echo -e "${YELLOW}Could not download bluetui (optional)${NC}"
        fi
    else
        echo -e "${YELLOW}Could not fetch bluetui release URL (optional)${NC}"
    fi
fi

# ─── IMPALA: TUI WiFi Manager (GitHub binary) ────────────────────────────────
echo ""
echo "Installing impala (TUI WiFi manager)..."
IMPALA_BIN="$INSTALL_HOME/.local/bin/impala"
case "$ARCH" in
    x86_64)  IMPALA_ASSET="impala-x86_64-unknown-linux-musl" ;;
    aarch64) IMPALA_ASSET="impala-aarch64-unknown-linux-musl" ;;
    *)       IMPALA_ASSET="" ;;
esac

if [ -z "$IMPALA_ASSET" ]; then
    echo -e "${YELLOW}impala: unsupported architecture ($ARCH) — skipped${NC}"
else
    IMPALA_URL=$(curl -s https://api.github.com/repos/pythops/impala/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$IMPALA_ASSET'))" 2>/dev/null)
    if [ -n "$IMPALA_URL" ]; then
        mkdir -p "$INSTALL_HOME/.local/bin"
        if curl -fsSL --connect-timeout 15 --max-time 60 -o "$IMPALA_BIN" "$IMPALA_URL" 2>/dev/null; then
            chmod +x "$IMPALA_BIN"
            chown "$INSTALL_USER:$INSTALL_USER" "$IMPALA_BIN"
            echo -e "${GREEN}✓ impala installed${NC}"
        else
            echo -e "${YELLOW}Could not download impala (optional)${NC}"
        fi
    else
        echo -e "${YELLOW}Could not fetch impala release URL (optional)${NC}"
    fi
fi

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

# ─── SUPERFILE: Terminal File Manager (GitHub binary) ────────────────────────
echo ""
echo "Installing superfile (spf)..."
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  SPF_ARCH="amd64" ;;
    aarch64) SPF_ARCH="arm64" ;;
    *)       SPF_ARCH="" ;;
esac

if [ -z "$SPF_ARCH" ]; then
    echo -e "${YELLOW}superfile: unsupported architecture ($ARCH) — skipped${NC}"
else
    SPF_URL=$(curl -s https://api.github.com/repos/yorukot/superfile/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] \
          if 'linux' in a['name'] and '$SPF_ARCH' in a['name']))" 2>/dev/null)
    if [ -n "$SPF_URL" ]; then
        TMP_DIR=$(mktemp -d)
        if curl -fsSL --connect-timeout 15 --max-time 120 "$SPF_URL" | tar -xz -C "$TMP_DIR" 2>/dev/null; then
            SPF_BIN=$(find "$TMP_DIR" -name "spf" -type f | head -1)
            if [ -n "$SPF_BIN" ]; then
                mkdir -p "$INSTALL_HOME/.local/bin"
                cp "$SPF_BIN" "$INSTALL_HOME/.local/bin/spf"
                chmod +x "$INSTALL_HOME/.local/bin/spf"
                chown "$INSTALL_USER:$INSTALL_USER" "$INSTALL_HOME/.local/bin/spf"
                echo -e "${GREEN}✓ superfile (spf) installed${NC}"
            fi
        else
            echo -e "${YELLOW}Could not download superfile (optional)${NC}"
        fi
        rm -rf "$TMP_DIR"
    else
        echo -e "${YELLOW}Could not fetch superfile release URL (optional)${NC}"
    fi
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
