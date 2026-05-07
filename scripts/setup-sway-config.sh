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

xdg-user-dirs-update 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Videos"

# Backup existing sway config
echo ""
echo "Backing up existing configuration files..."
mkdir -p "$CONFIG_DIR"
for file in config swaylock.conf; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        cp "$CONFIG_DIR/$file" "$CONFIG_DIR/$file.backup"
        echo -e "${GREEN}Backed up: $file${NC}"
    fi
done

# Install sway config
echo ""
echo "Installing Sway configuration files..."
cp "$CONFIGS_DIR/sway/config"         "$CONFIG_DIR/config"
cp "$CONFIGS_DIR/sway/swaylock.conf"  "$CONFIG_DIR/swaylock.conf"
echo -e "${GREEN}Installed: ~/.config/sway/${NC}"

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

# Install Alacritty terminal config
echo ""
echo "Installing Alacritty configuration..."
mkdir -p "$HOME/.config/alacritty/themes"
cp "$CONFIGS_DIR/alacritty/alacritty.toml"  "$HOME/.config/alacritty/alacritty.toml"
cp "$CONFIGS_DIR/alacritty/themes/"*        "$HOME/.config/alacritty/themes/"
echo -e "${GREEN}Installed: ~/.config/alacritty/${NC}"

# Install Kitty terminal config
echo ""
echo "Installing Kitty configuration..."
mkdir -p "$HOME/.config/kitty"
cp "$CONFIGS_DIR/kitty/kitty.conf"           "$HOME/.config/kitty/kitty.conf"
cp "$CONFIGS_DIR/kitty/current-theme.conf"   "$HOME/.config/kitty/current-theme.conf"
echo -e "${GREEN}Installed: ~/.config/kitty/${NC}"

# Install Tmux config
echo ""
echo "Installing Tmux configuration..."
mkdir -p "$HOME/.config/tmux"
cp "$CONFIGS_DIR/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
echo -e "${GREEN}Installed: ~/.config/tmux/tmux.conf${NC}"

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
EOF
    echo -e "${GREEN}Installed: Wayland env vars in ~/.bash_profile${NC}"
else
    echo -e "${GREEN}Wayland env vars already present in ~/.bash_profile${NC}"
fi

# Install helper scripts to ~/.local/bin/
echo ""
echo "Installing helper scripts to ~/.local/bin/..."
mkdir -p "$HOME/.local/bin"
for helper in powermenu.sh wallpaper-next.sh theme-picker.sh check-updates.sh update-system.sh; do
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
echo "  - ~/.config/sway/              (Sway configs)"
echo "  - ~/.config/mako/config        (notification daemon)"
echo "  - ~/.config/kanshi/config      (multi-monitor profiles)"
echo "  - ~/.config/waybar/            (status bar)"
echo "  - ~/.config/wofi/              (app launcher)"
echo "  - ~/.config/alacritty/         (terminal)"
echo "  - ~/.config/kitty/             (terminal)"
echo "  - ~/.config/tmux/              (multiplexer)"
echo "  - ~/.bashrc / ~/.bash_profile  (shell config)"
echo "  - ~/.local/bin/                (helper scripts)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set wallpaper:    bash scripts/setup-wallpaper.sh"
echo "2. Configure theme:  bash scripts/setup-theme.sh"
echo "3. Verify install:   bash scripts/verify-install.sh"
echo "4. Add wallpaper images to ~/Pictures/Wallpapers/"
echo "5. Reboot — greetd/tuigreet lancera automatiquement Sway"
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
