#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Sway Configuration Setup ===${NC}"
echo "Installs Sway configuration files."
echo ""

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPTS_DIR/../configs" && pwd)"
CONFIG_DIR="$HOME/.config/sway"

echo -e "${YELLOW}This will install configuration files into $CONFIG_DIR${NC}"
echo -e "${YELLOW}Existing files will be backed up with .backup extension${NC}"

if [ "${NONINTERACTIVE:-0}" != "1" ]; then
    echo -e "${YELLOW}Do you want to continue? (y/n)${NC}"
    read -r confirm

    while [[ ! "$confirm" =~ ^[YyNn]$ ]]; do
        echo -e "${YELLOW}Please enter y or n:${NC}"
        read -r confirm
    done

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

xdg-user-dirs-update 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos"

echo ""
echo "Installing wallpapers..."
for theme_dir in "$CONFIGS_DIR/wallpapers/"/*/; do
    slug=$(basename "$theme_dir")
    mkdir -p "$HOME/Pictures/Wallpapers/$slug"
    find "$theme_dir" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        -exec cp {} "$HOME/Pictures/Wallpapers/$slug/" \;
    echo -e "${GREEN}Installed: ~/Pictures/Wallpapers/$slug/${NC}"
done

mkdir -p "$HOME/.local/share"
[ -f "$HOME/.local/share/current-theme" ] || echo "gruvbox" > "$HOME/.local/share/current-theme"

# Backup existing sway config
echo ""
echo "Backing up existing configuration files..."
mkdir -p "$CONFIG_DIR"
for file in config; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        cp "$CONFIG_DIR/$file" "$CONFIG_DIR/$file.backup"
        echo -e "${GREEN}Backed up: $file${NC}"
    fi
done

# Install sway config
echo ""
echo "Installing Sway configuration files..."
cp "$CONFIGS_DIR/sway/config" "$CONFIG_DIR/config"
echo -e "${GREEN}Installed: ~/.config/sway/config${NC}"

# Install hyprlock config (hyprlock looks for it in ~/.config/hypr/)
echo ""
echo "Installing hyprlock configuration..."
mkdir -p "$HOME/.config/hypr"
cp "$CONFIGS_DIR/hypr/hyprlock.conf" "$HOME/.config/hypr/hyprlock.conf"
echo -e "${GREEN}Installed: ~/.config/hypr/hyprlock.conf${NC}"

# Install mako notification config
echo ""
echo "Installing Mako notification configuration..."
mkdir -p "$HOME/.config/mako"
cp "$CONFIGS_DIR/mako/config" "$HOME/.config/mako/config"
echo -e "${GREEN}Installed: ~/.config/mako/config${NC}"

# Install kanshi multi-monitor config
echo ""
echo "Installing Kanshi multi-monitor configuration..."
mkdir -p "$HOME/.config/kanshi"
cp "$CONFIGS_DIR/kanshi/config" "$HOME/.config/kanshi/config"
echo -e "${GREEN}Installed: ~/.config/kanshi/config${NC}"

# Install XDG portal config (file picker → gtk, screenshot → wlr)
echo ""
echo "Installing XDG portal configuration..."
mkdir -p "$HOME/.config/xdg-desktop-portal"
cp "$CONFIGS_DIR/xdg-desktop-portal/portals.conf" "$HOME/.config/xdg-desktop-portal/portals.conf"
echo -e "${GREEN}Installed: ~/.config/xdg-desktop-portal/portals.conf${NC}"

# Install screensaver config
echo ""
echo "Installing screensaver configuration..."
mkdir -p "$HOME/.config/screensaver"
cp "$CONFIGS_DIR/screensaver/content.txt" "$HOME/.config/screensaver/content.txt"
echo -e "${GREEN}Installed: ~/.config/screensaver/content.txt${NC}"

# Install waybar config
echo ""
echo "Installing Waybar configuration..."
mkdir -p "$HOME/.config/waybar/scripts"
cp "$CONFIGS_DIR/waybar/config"       "$HOME/.config/waybar/config"
cp "$CONFIGS_DIR/waybar/style.css"    "$HOME/.config/waybar/style.css"
cp "$CONFIGS_DIR/waybar/colors.css"   "$HOME/.config/waybar/colors.css"
cp "$CONFIGS_DIR/waybar/scripts/"*    "$HOME/.config/waybar/scripts/"
chmod +x "$HOME/.config/waybar/scripts/"*
echo -e "${GREEN}Installed: ~/.config/waybar/${NC}"

# Install wofi launcher config
echo ""
echo "Installing Wofi launcher configuration..."
mkdir -p "$HOME/.config/wofi"
cp "$CONFIGS_DIR/wofi/config"     "$HOME/.config/wofi/config"
cp "$CONFIGS_DIR/wofi/style.css"  "$HOME/.config/wofi/style.css"
echo -e "${GREEN}Installed: ~/.config/wofi/${NC}"

# Install Kitty terminal config
echo ""
echo "Installing Kitty configuration..."
mkdir -p "$HOME/.config/kitty/themes"
cp "$CONFIGS_DIR/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
cp "$CONFIGS_DIR/kitty/current-theme.conf"   "$HOME/.config/kitty/current-theme.conf"
cp "$CONFIGS_DIR/kitty/themes/"*.conf        "$HOME/.config/kitty/themes/"
echo -e "${GREEN}Installed: ~/.config/kitty/${NC}"

# Install Tmux config
echo ""
echo "Installing Tmux configuration..."
mkdir -p "$HOME/.config/tmux"
cp "$CONFIGS_DIR/tmux/tmux.conf"   "$HOME/.config/tmux/tmux.conf"
cp "$CONFIGS_DIR/tmux/theme.conf"  "$HOME/.config/tmux/theme.conf"
cp "$CONFIGS_DIR/tmux/theme.tmpl"  "$HOME/.config/tmux/theme.tmpl"
echo -e "${GREEN}Installed: ~/.config/tmux/${NC}"


# Install theme variable files
echo ""
echo "Installing theme variable files..."
mkdir -p "$HOME/.config/themes"
cp "$CONFIGS_DIR/themes/"*.sh "$HOME/.config/themes/"
echo -e "${GREEN}Installed: ~/.config/themes/${NC}"

# Install config templates (used by theme-picker.sh via envsubst)
echo ""
echo "Installing config templates..."
cp "$CONFIGS_DIR/waybar/colors.tmpl" "$HOME/.config/waybar/colors.tmpl"
cp "$CONFIGS_DIR/mako/config.tmpl"   "$HOME/.config/mako/config.tmpl"
echo -e "${GREEN}Installed: colors.tmpl, config.tmpl${NC}"

# Install TPM if absent and bootstrap plugins
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi
"$HOME/.config/tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true
echo -e "${GREEN}✓ tmux plugins installed${NC}"

# Install .desktop files (web apps)
echo ""
echo "Installing desktop entries..."
mkdir -p "$HOME/.local/share/applications"
cp "$CONFIGS_DIR/applications/"*.desktop "$HOME/.local/share/applications/"
echo -e "${GREEN}Installed: ~/.local/share/applications/${NC}"

# Download Slack icon (needed for the webapp .desktop entry)
echo ""
echo "Installing Slack icon..."
SLACK_ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
mkdir -p "$SLACK_ICON_DIR"
if [ ! -f "$SLACK_ICON_DIR/slack.png" ]; then
    if curl -fsSL --connect-timeout 10 --max-time 30 \
        -o "$SLACK_ICON_DIR/slack.png" \
        "https://a.slack-edge.com/80588/marketing/img/meta/slack_hash_256.png" 2>/dev/null; then
        echo -e "${GREEN}✓ Slack icon installed${NC}"
    else
        echo -e "${YELLOW}Could not download Slack icon (skipping)${NC}"
    fi
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
else
    echo -e "${GREEN}Slack icon already present${NC}"
fi

# Install .bashrc
echo ""
echo "Installing .bashrc..."
[ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
cp "$CONFIGS_DIR/bashrc/.bashrc" "$HOME/.bashrc"
echo -e "${GREEN}Installed: ~/.bashrc${NC}"

# Set Sway environment variables in .bash_profile
echo ""
echo "Configuring Wayland environment variables..."
PROFILE="$HOME/.bash_profile"
if ! grep -q "XDG_CURRENT_DESKTOP=sway" "$PROFILE" 2>/dev/null; then
    cat >> "$PROFILE" << 'EOF'

# Wayland / Sway environment
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=sway
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export XCURSOR_SIZE=24

# Auto-start Sway on TTY1 login (autologin via getty)
[[ -z "${WAYLAND_DISPLAY:-}" && "${XDG_VTNR:-}" -eq 1 ]] && exec sway
EOF
    echo -e "${GREEN}Installed: Wayland env vars in ~/.bash_profile${NC}"
else
    echo -e "${GREEN}Wayland env vars already present in ~/.bash_profile${NC}"
fi

# Install helper scripts to ~/.local/bin/
echo ""
echo "Installing helper scripts to ~/.local/bin/..."
mkdir -p "$HOME/.local/bin"
for helper in powermenu.sh wallpaper-next.sh theme-picker.sh check-updates.sh update-system.sh screensaver-launch.sh screensaver-stop.sh screensaver-tte.sh; do
    if [ -f "$SCRIPTS_DIR/$helper" ]; then
        cp "$SCRIPTS_DIR/$helper" "$HOME/.local/bin/$helper"
        chmod +x "$HOME/.local/bin/$helper"
        echo -e "${GREEN}Installed: ~/.local/bin/$helper${NC}"
    else
        echo -e "${YELLOW}Not found: $SCRIPTS_DIR/$helper (skipped)${NC}"
    fi
done

echo ""
echo -e "${GREEN}=== Configuration Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Configuration files installed:${NC}"
echo "  - ~/.config/sway/              (Sway config)"
echo "  - ~/.config/hypr/hyprlock.conf (lock screen)"
echo "  - ~/.config/mako/config        (notification daemon)"
echo "  - ~/.config/kanshi/config      (multi-monitor profiles)"
echo "  - ~/.config/waybar/            (status bar)"
echo "  - ~/.config/wofi/              (app launcher)"
echo "  - ~/.config/kitty/             (terminal)"
echo "  - ~/.config/tmux/              (multiplexer + theme.tmpl)"
echo "  - ~/.config/themes/            (per-theme color variables)"
echo "  - ~/.bashrc / ~/.bash_profile  (shell config)"
echo "  - ~/.local/bin/                (helper scripts)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set wallpaper:    bash scripts/setup-wallpaper.sh"
echo "2. Configure theme:  bash scripts/setup-theme.sh"
echo "3. Verify install:   bash scripts/verify-install.sh"
echo "4. Add wallpaper images to ~/Pictures/Wallpapers/"
echo "5. Reboot — autologin on TTY1, Sway starts automatically"
echo ""
echo -e "${GREEN}Key shortcuts:${NC}"
echo "  SUPER + Return    : Open terminal"
echo "  SUPER + D         : Application launcher"
echo "  SUPER + E         : File manager"
echo "  SUPER + Q         : Close window"
echo "  SUPER + F         : Fullscreen"
echo "  SUPER + L         : Lock screen"
echo "  SUPER + C         : Clipboard history"
echo "  SUPER + SHIFT + R : Screen recording toggle"
echo "  SUPER + 1-9       : Switch workspace"
echo "  Print             : Screenshot (area → clipboard)"
echo "  SUPER + Print     : Screenshot (saved to ~/Pictures/Screenshots/)"
echo ""
