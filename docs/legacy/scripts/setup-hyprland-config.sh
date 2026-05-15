#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Hyprland Configuration Setup ===${NC}"
echo "This script will install Hyprland configuration files"
echo "inspired by Omarchy's clean and modular structure"
echo ""

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPTS_DIR/../configs" && pwd)"
CONFIG_DIR="$HOME/.config/hypr"

# Ask user for confirmation
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

# Ensure XDG user dirs exist
xdg-user-dirs-update 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"

# Backup existing hypr configs
echo ""
echo "Backing up existing configuration files..."
mkdir -p "$CONFIG_DIR"
for file in hyprland.conf envs.conf monitors.conf input.conf bindings.conf looknfeel.conf \
            autostart.conf windowrules.conf workspaces.conf xdph.conf hypridle.conf hyprlock.conf; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        cp "$CONFIG_DIR/$file" "$CONFIG_DIR/$file.backup"
        echo -e "${GREEN}Backed up: $file${NC}"
    fi
done

# Install hypr configs
echo ""
echo "Installing Hyprland configuration files..."
cp "$CONFIGS_DIR/hypr/"* "$CONFIG_DIR/"
echo -e "${GREEN}Installed: ~/.config/hypr/${NC}"

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
cp "$CONFIGS_DIR/waybar/config" "$HOME/.config/waybar/config"
cp "$CONFIGS_DIR/waybar/style.css" "$HOME/.config/waybar/style.css"
cp "$CONFIGS_DIR/waybar/colors.css" "$HOME/.config/waybar/colors.css"
cp "$CONFIGS_DIR/waybar/scripts/"* "$HOME/.config/waybar/scripts/"
chmod +x "$HOME/.config/waybar/scripts/"*
echo -e "${GREEN}Installed: ~/.config/waybar/${NC}"

# Install wofi launcher config
echo ""
echo "Installing Wofi launcher configuration..."
mkdir -p "$HOME/.config/wofi"
cp "$CONFIGS_DIR/wofi/config" "$HOME/.config/wofi/config"
cp "$CONFIGS_DIR/wofi/style.css" "$HOME/.config/wofi/style.css"
echo -e "${GREEN}Installed: ~/.config/wofi/${NC}"

# Install wlogout power menu config
echo ""
echo "Installing Wlogout power menu configuration..."
mkdir -p "$HOME/.config/wlogout"
cp "$CONFIGS_DIR/wlogout/layout" "$HOME/.config/wlogout/layout"
cp "$CONFIGS_DIR/wlogout/style.css" "$HOME/.config/wlogout/style.css"
echo -e "${GREEN}Installed: ~/.config/wlogout/${NC}"

# Install Alacritty terminal config
echo ""
echo "Installing Alacritty configuration..."
mkdir -p "$HOME/.config/alacritty/themes"
cp "$CONFIGS_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$CONFIGS_DIR/alacritty/themes/"* "$HOME/.config/alacritty/themes/"
echo -e "${GREEN}Installed: ~/.config/alacritty/${NC}"

# Install Kitty terminal config
echo ""
echo "Installing Kitty configuration..."
mkdir -p "$HOME/.config/kitty"
cp "$CONFIGS_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp "$CONFIGS_DIR/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"
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
echo "  - ~/.config/hypr/              (Hyprland configs)"
echo "  - ~/.config/mako/config        (notification daemon)"
echo "  - ~/.config/kanshi/config      (multi-monitor profiles)"
echo "  - ~/.config/waybar/            (status bar)"
echo "  - ~/.config/wofi/              (app launcher)"
echo "  - ~/.config/wlogout/           (power menu)"
echo "  - ~/.config/alacritty/         (terminal)"
echo "  - ~/.config/kitty/             (terminal)"
echo "  - ~/.config/tmux/              (multiplexer)"
echo "  - ~/.bashrc                    (shell config)"
echo "  - ~/.local/bin/                (helper scripts)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set wallpaper:    bash scripts/setup-wallpaper.sh"
echo "2. Configure theme:  bash scripts/setup-theme.sh"
echo "3. Configure lock:   bash scripts/setup-hyprlock.sh"
echo "4. Verify install:   bash scripts/verify-install.sh"
echo "5. Add wallpaper images to ~/Pictures/Wallpapers/"
echo "6. Logout and select 'Hyprland' from your display manager"
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
