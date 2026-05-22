#!/bin/bash
# install-github-bins.sh — Install/update GitHub-sourced binaries
# Usage: install-github-bins.sh [--check] [--user USER]
#   --check  : print update count for waybar (JSON-compatible)
#   --user   : install for this user (default: SUDO_USER or current user)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECK_MODE=0
INSTALL_USER=""

while [ $# -gt 0 ]; do
    case "$1" in
        --check) CHECK_MODE=1 ;;
        --user)  shift; INSTALL_USER="$1" ;;
    esac
    shift
done

INSTALL_USER="${INSTALL_USER:-${SUDO_USER:-$USER}}"
INSTALL_HOME="/home/$INSTALL_USER"
BIN_DIR="$INSTALL_HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

ARCH=$(uname -m)
UPDATE_COUNT=0
UPDATE_NAMES=()

# ─── helpers ──────────────────────────────────────────────────────────────────

latest_tag() {
    curl -s --connect-timeout 5 "https://api.github.com/repos/$1/releases/latest" \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))" 2>/dev/null
}

needs_update() {
    local installed="$1" latest="$2"
    [ -n "$installed" ] && [ -n "$latest" ] && [ "$installed" != "$latest" ]
}

# ─── bluetui ──────────────────────────────────────────────────────────────────

install_bluetui() {
    case "$ARCH" in
        x86_64)  asset="bluetui-x86_64-linux-musl" ;;
        aarch64) asset="bluetui-aarch64-linux-musl" ;;
        *) return ;;
    esac
    local url
    url=$(curl -s https://api.github.com/repos/pythops/bluetui/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$asset'))" 2>/dev/null)
    [ -z "$url" ] && return
    curl -fsSL --connect-timeout 15 --max-time 60 -o "$BIN_DIR/bluetui" "$url" 2>/dev/null \
        && chmod +x "$BIN_DIR/bluetui" && chown "$INSTALL_USER:$INSTALL_USER" "$BIN_DIR/bluetui"
}

check_bluetui() {
    command -v bluetui &>/dev/null || { install_bluetui; return; }
    local installed latest
    installed=$(bluetui --version 2>/dev/null | awk '{print $2}')
    latest=$(latest_tag "pythops/bluetui")
    if needs_update "$installed" "$latest"; then
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
        UPDATE_NAMES+=("bluetui→$latest")
        [ "$CHECK_MODE" -eq 0 ] && { echo -e "${YELLOW}Updating bluetui $installed → $latest${NC}"; install_bluetui; echo -e "${GREEN}✓ bluetui updated${NC}"; }
    else
        [ "$CHECK_MODE" -eq 0 ] && echo -e "${GREEN}✓ bluetui $installed (up to date)${NC}"
    fi
}

# ─── impala ───────────────────────────────────────────────────────────────────

install_impala() {
    case "$ARCH" in
        x86_64)  asset="impala-x86_64-unknown-linux-musl" ;;
        aarch64) asset="impala-aarch64-unknown-linux-musl" ;;
        *) return ;;
    esac
    local url
    url=$(curl -s https://api.github.com/repos/pythops/impala/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$asset'))" 2>/dev/null)
    [ -z "$url" ] && return
    curl -fsSL --connect-timeout 15 --max-time 60 -o "$BIN_DIR/impala" "$url" 2>/dev/null \
        && chmod +x "$BIN_DIR/impala" && chown "$INSTALL_USER:$INSTALL_USER" "$BIN_DIR/impala"
}

check_impala() {
    command -v impala &>/dev/null || { install_impala; return; }
    local installed latest
    installed=$(impala --version 2>/dev/null | awk '{print $2}')
    latest=$(latest_tag "pythops/impala")
    if needs_update "$installed" "$latest"; then
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
        UPDATE_NAMES+=("impala→$latest")
        [ "$CHECK_MODE" -eq 0 ] && { echo -e "${YELLOW}Updating impala $installed → $latest${NC}"; install_impala; echo -e "${GREEN}✓ impala updated${NC}"; }
    else
        [ "$CHECK_MODE" -eq 0 ] && echo -e "${GREEN}✓ impala $installed (up to date)${NC}"
    fi
}

# ─── yazi ─────────────────────────────────────────────────────────────────────

install_yazi() {
    case "$ARCH" in
        x86_64)  asset="yazi-x86_64-unknown-linux-musl.zip" ;;
        aarch64) asset="yazi-aarch64-unknown-linux-musl.zip" ;;
        *) return ;;
    esac
    local url tmp_zip tmp_dir
    url=$(curl -s https://api.github.com/repos/sxyazi/yazi/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$asset'))" 2>/dev/null)
    [ -z "$url" ] && return
    tmp_zip=$(mktemp /tmp/yazi-XXXXXX.zip)
    tmp_dir=$(mktemp -d)
    curl -fsSL --connect-timeout 15 --max-time 120 -o "$tmp_zip" "$url" 2>/dev/null \
        && unzip -o "$tmp_zip" "*/yazi" -d "$tmp_dir" 2>/dev/null \
        && cp "$(find "$tmp_dir" -name "yazi" -type f | head -1)" "$BIN_DIR/yazi" \
        && chmod +x "$BIN_DIR/yazi" && chown "$INSTALL_USER:$INSTALL_USER" "$BIN_DIR/yazi"
    rm -f "$tmp_zip"; rm -rf "$tmp_dir"
}

check_yazi() {
    command -v yazi &>/dev/null || { install_yazi; return; }
    local installed latest
    installed=$(yazi --version 2>/dev/null | awk '{print $2}')
    latest=$(latest_tag "sxyazi/yazi")
    if needs_update "$installed" "$latest"; then
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
        UPDATE_NAMES+=("yazi→$latest")
        [ "$CHECK_MODE" -eq 0 ] && { echo -e "${YELLOW}Updating yazi $installed → $latest${NC}"; install_yazi; echo -e "${GREEN}✓ yazi updated${NC}"; }
    else
        [ "$CHECK_MODE" -eq 0 ] && echo -e "${GREEN}✓ yazi $installed (up to date)${NC}"
    fi
}

# ─── superfile ────────────────────────────────────────────────────────────────

install_spf() {
    case "$ARCH" in
        x86_64)  spf_arch="amd64" ;;
        aarch64) spf_arch="arm64" ;;
        *) return ;;
    esac
    local url tmp_dir
    url=$(curl -s https://api.github.com/repos/yorukot/superfile/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] \
          if 'linux' in a['name'] and '$spf_arch' in a['name']))" 2>/dev/null)
    [ -z "$url" ] && return
    tmp_dir=$(mktemp -d)
    curl -fsSL --connect-timeout 15 --max-time 120 "$url" 2>/dev/null | tar -xz -C "$tmp_dir" \
        && cp "$(find "$tmp_dir" -name "spf" -type f | head -1)" "$BIN_DIR/spf" \
        && chmod +x "$BIN_DIR/spf" && chown "$INSTALL_USER:$INSTALL_USER" "$BIN_DIR/spf"
    rm -rf "$tmp_dir"
}

check_spf() {
    command -v spf &>/dev/null || { install_spf; return; }
    local installed latest
    installed=$(spf --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
    latest=$(latest_tag "yorukot/superfile")
    if needs_update "$installed" "$latest"; then
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
        UPDATE_NAMES+=("spf→$latest")
        [ "$CHECK_MODE" -eq 0 ] && { echo -e "${YELLOW}Updating spf $installed → $latest${NC}"; install_spf; echo -e "${GREEN}✓ spf updated${NC}"; }
    else
        [ "$CHECK_MODE" -eq 0 ] && echo -e "${GREEN}✓ spf $installed (up to date)${NC}"
    fi
}

# ─── zen browser ─────────────────────────────────────────────────────────────

install_zen() {
    case "$ARCH" in
        x86_64)  asset="zen.linux-x86_64.tar.xz" ;;
        aarch64) asset="zen.linux-aarch64.tar.xz" ;;
        *) return ;;
    esac
    local url tmp_archive tmp_dir zen_src zen_dir
    zen_dir="$INSTALL_HOME/.local/share/zen-browser"
    url=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest \
        | python3 -c "import sys,json; r=json.load(sys.stdin); \
          print(next(a['browser_download_url'] for a in r['assets'] if a['name']=='$asset'))" 2>/dev/null)
    [ -z "$url" ] && return
    tmp_archive=$(mktemp /tmp/zen-XXXXXX.tar.xz)
    tmp_dir=$(mktemp -d)
    if ! curl -fsSL --connect-timeout 15 --max-time 300 -o "$tmp_archive" "$url" 2>/dev/null; then
        rm -f "$tmp_archive"; rm -rf "$tmp_dir"; return
    fi
    if ! tar -xf "$tmp_archive" -C "$tmp_dir" 2>/dev/null; then
        rm -f "$tmp_archive"; rm -rf "$tmp_dir"; return
    fi
    zen_src=$(find "$tmp_dir" -maxdepth 1 -mindepth 1 -type d | head -1)
    if [ -z "$zen_src" ] || [ ! -f "$zen_src/zen" ]; then
        rm -f "$tmp_archive"; rm -rf "$tmp_dir"; return
    fi
    rm -rf "$zen_dir"
    mv "$zen_src" "$zen_dir"
    ln -sf "$zen_dir/zen" "$BIN_DIR/zen"
    local icon_src
    icon_src=$(find "$zen_dir" -name "default128.png" | head -1)
    if [ -n "$icon_src" ]; then
        mkdir -p "$INSTALL_HOME/.local/share/icons/hicolor/128x128/apps"
        cp "$icon_src" "$INSTALL_HOME/.local/share/icons/hicolor/128x128/apps/zen-browser.png"
    fi
    mkdir -p "$INSTALL_HOME/.local/share/applications"
    cat > "$INSTALL_HOME/.local/share/applications/zen-browser.desktop" << EOF
[Desktop Entry]
Name=Zen Browser
Exec=$zen_dir/zen %u
Icon=zen-browser
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=zen-browser
EOF
    chown -R "$INSTALL_USER:$INSTALL_USER" "$zen_dir" "$BIN_DIR/zen" \
        "$INSTALL_HOME/.local/share/icons" \
        "$INSTALL_HOME/.local/share/applications/zen-browser.desktop" 2>/dev/null || true
    rm -f "$tmp_archive"; rm -rf "$tmp_dir"
}

check_zen() {
    command -v zen &>/dev/null || { install_zen; return; }
    local installed latest
    installed=$(zen --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+\S*' | head -1)
    latest=$(latest_tag "zen-browser/desktop")
    if needs_update "$installed" "$latest"; then
        UPDATE_COUNT=$((UPDATE_COUNT + 1))
        UPDATE_NAMES+=("zen→$latest")
        [ "$CHECK_MODE" -eq 0 ] && { echo -e "${YELLOW}Updating zen $installed → $latest${NC}"; install_zen; echo -e "${GREEN}✓ zen updated${NC}"; }
    else
        [ "$CHECK_MODE" -eq 0 ] && echo -e "${GREEN}✓ zen $installed (up to date)${NC}"
    fi
}

# ─── main ─────────────────────────────────────────────────────────────────────

check_bluetui
check_impala
check_yazi
check_spf
check_zen

if [ "$CHECK_MODE" -eq 1 ]; then
    echo "$UPDATE_COUNT ${UPDATE_NAMES[*]}"
fi
