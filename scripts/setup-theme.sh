#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$(cd "$SCRIPTS_DIR/../configs" && pwd)"

echo -e "${GREEN}=== Theme Configuration ===${NC}"
echo "Configures GTK theme, icons, cursor, Qt5, and Neovim"
echo ""

ENVS_CONF="$HOME/.config/hypr/envs.conf"
AUTOSTART_CONF="$HOME/.config/hypr/autostart.conf"

# --- PACKAGE INSTALLATION ---
declare -a THEME_PACKAGES=(
    "arc-theme"
    "numix-gtk-theme"
    "papirus-icon-theme"
    "qt5ct"
    "adwaita-qt"
    "nwg-look"
    "xsettingsd"
    "neovim"
    "fd-find"
)

# Cursor theme — try bibata first, fallback to breeze
CURSOR_PACKAGES=("bibata-cursor-theme" "breeze-cursor-theme")

echo -e "${YELLOW}Install theme packages (arc, papirus, qt5ct, neovim, etc.)? (y/n)${NC}"
read -r install_theme_pkgs
while [[ ! "$install_theme_pkgs" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r install_theme_pkgs
done

if [[ "$install_theme_pkgs" =~ ^[Yy]$ ]]; then
    sudo apt update
    for pkg in "${THEME_PACKAGES[@]}"; do
        if check_package "$pkg"; then
            if install_package "$pkg"; then
                SUCCESSFUL_PACKAGES+=("$pkg")
            else
                FAILED_PACKAGES+=("$pkg")
            fi
        else
            echo -e "${YELLOW}Not found in repos: $pkg${NC}"
            FAILED_PACKAGES+=("$pkg")
        fi
    done

    # Install cursor theme (bibata preferred, breeze as fallback)
    CURSOR_PKG_INSTALLED=""
    for cpkg in "${CURSOR_PACKAGES[@]}"; do
        if check_package "$cpkg"; then
            if install_package "$cpkg"; then
                SUCCESSFUL_PACKAGES+=("$cpkg")
                CURSOR_PKG_INSTALLED="$cpkg"
                break
            fi
        fi
    done
    [ -z "$CURSOR_PKG_INSTALLED" ] && echo -e "${YELLOW}No cursor package installed — using system default${NC}"
fi

# --- GTK THEME SELECTION ---
echo ""
echo -e "${YELLOW}Select GTK theme:${NC}"
echo "  1) Arc-Dark   (flat, dark)"
echo "  2) Arc        (flat, light)"
echo "  3) Numix-Dark (rounded, dark)"
echo "  4) Adwaita    (GNOME default)"
read -r gtk_choice
while [[ ! "$gtk_choice" =~ ^[1-4]$ ]]; do
    echo -e "${YELLOW}Please enter 1-4:${NC}"
    read -r gtk_choice
done

case "$gtk_choice" in
    1) GTK_THEME="Arc-Dark" ;;
    2) GTK_THEME="Arc" ;;
    3) GTK_THEME="Numix-Dark" ;;
    4) GTK_THEME="Adwaita" ;;
esac

ICON_THEME="Papirus-Dark"

# --- CURSOR THEME SELECTION ---
echo ""
echo -e "${YELLOW}Select cursor theme:${NC}"
echo "  1) Bibata-Modern-Classic  (modern, compact)"
echo "  2) Breeze                 (KDE default)"
echo "  3) Adwaita                (GNOME default)"
read -r cursor_choice
while [[ ! "$cursor_choice" =~ ^[1-3]$ ]]; do
    echo -e "${YELLOW}Please enter 1-3:${NC}"
    read -r cursor_choice
done

case "$cursor_choice" in
    1) CURSOR_THEME="Bibata-Modern-Classic" ; CURSOR_SIZE=24 ;;
    2) CURSOR_THEME="Breeze" ; CURSOR_SIZE=24 ;;
    3) CURSOR_THEME="Adwaita" ; CURSOR_SIZE=24 ;;
esac

echo ""
echo -e "${GREEN}Applying: GTK=$GTK_THEME | Icons=$ICON_THEME | Cursor=$CURSOR_THEME${NC}"

# --- GTK SETTINGS ---
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF

cat > "$HOME/.config/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF

echo -e "${GREEN}Written: gtk-3.0/settings.ini and gtk-4.0/settings.ini${NC}"

# --- CURSOR DEFAULT ---
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$CURSOR_THEME
EOF

echo -e "${GREEN}Written: ~/.icons/default/index.theme${NC}"

# --- XSETTINGSD ---
mkdir -p "$HOME/.config/xsettingsd"
cat > "$HOME/.config/xsettingsd/xsettingsd.conf" << EOF
Net/ThemeName "$GTK_THEME"
Net/IconThemeName "$ICON_THEME"
Gtk/CursorThemeName "$CURSOR_THEME"
Gtk/CursorThemeSize $CURSOR_SIZE
EOF

echo -e "${GREEN}Written: ~/.config/xsettingsd/xsettingsd.conf${NC}"

# Add xsettingsd to autostart if not already present
if [ -f "$AUTOSTART_CONF" ] && ! grep -q "xsettingsd" "$AUTOSTART_CONF"; then
    printf '\n# GTK settings daemon (for Wayland sessions)\nexec-once = xsettingsd\n' >> "$AUTOSTART_CONF"
    echo -e "${GREEN}xsettingsd added to autostart.conf${NC}"
fi

# --- QT5CT ---
mkdir -p "$HOME/.config/qt5ct"
cat > "$HOME/.config/qt5ct/qt5ct.conf" << EOF
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=$ICON_THEME
standard_dialogs=default
style=adwaita-dark

[Fonts]
fixed=@Variant(\0\0\0@\0\0\0\x12JetBrains Mono\0\0\0\0\0\0\0\0\0\0\0\0\x9\0\0\0\x64\0)
general=@Variant(\0\0\0@\0\0\0\nNoto Sans\0\0\0\0\0\0\0\0\0\0\0\0\x9\0\0\0\x8c\0)
EOF

echo -e "${GREEN}Written: ~/.config/qt5ct/qt5ct.conf${NC}"

# --- UPDATE envs.conf ---
if [ -f "$ENVS_CONF" ]; then
    # Update XCURSOR_SIZE if present, else append
    if grep -q "XCURSOR_SIZE" "$ENVS_CONF"; then
        sed -i "s|env = XCURSOR_SIZE,.*|env = XCURSOR_SIZE,$CURSOR_SIZE|" "$ENVS_CONF"
    else
        echo "env = XCURSOR_SIZE,$CURSOR_SIZE" >> "$ENVS_CONF"
    fi
    # Add XCURSOR_THEME if not present
    if ! grep -q "XCURSOR_THEME" "$ENVS_CONF"; then
        echo "env = XCURSOR_THEME,$CURSOR_THEME" >> "$ENVS_CONF"
    else
        sed -i "s|env = XCURSOR_THEME,.*|env = XCURSOR_THEME,$CURSOR_THEME|" "$ENVS_CONF"
    fi
    echo -e "${GREEN}envs.conf updated (XCURSOR_THEME, XCURSOR_SIZE)${NC}"
fi

# --- NEOVIM SETUP ---
echo ""
echo -e "${YELLOW}Set up Neovim with lazy.nvim? (y/n)${NC}"
read -r setup_nvim
while [[ ! "$setup_nvim" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r setup_nvim
done

if [[ "$setup_nvim" =~ ^[Yy]$ ]]; then
    NVIM_CONFIG="$HOME/.config/nvim"
    PROCEED_NVIM=true

    # Guard against stow-managed config
    if [ -d "$NVIM_CONFIG" ]; then
        echo -e "${YELLOW}~/.config/nvim already exists (may be stow-managed).${NC}"
        echo -e "${YELLOW}Overwrite? (y/n)${NC}"
        read -r overwrite_nvim
        while [[ ! "$overwrite_nvim" =~ ^[YyNn]$ ]]; do
            echo -e "${YELLOW}Please enter y or n:${NC}"
            read -r overwrite_nvim
        done
        [[ "$overwrite_nvim" =~ ^[Nn]$ ]] && PROCEED_NVIM=false
    fi

    if [[ "$PROCEED_NVIM" == true ]]; then
        mkdir -p "$NVIM_CONFIG/lua/config" "$NVIM_CONFIG/lua/plugins"
        cp "$CONFIGS_DIR/nvim/init.lua" "$NVIM_CONFIG/init.lua"
        cp "$CONFIGS_DIR/nvim/lua/config/lazy.lua" "$NVIM_CONFIG/lua/config/lazy.lua"
        cp "$CONFIGS_DIR/nvim/lua/config/options.lua" "$NVIM_CONFIG/lua/config/options.lua"
        cp "$CONFIGS_DIR/nvim/lua/config/keymaps.lua" "$NVIM_CONFIG/lua/config/keymaps.lua"
        cp "$CONFIGS_DIR/nvim/lua/config/autocmds.lua" "$NVIM_CONFIG/lua/config/autocmds.lua"
        cp "$CONFIGS_DIR/nvim/lua/plugins/colorscheme.lua" "$NVIM_CONFIG/lua/plugins/colorscheme.lua"
        echo -e "${GREEN}Neovim config installed at $NVIM_CONFIG${NC}"
        echo "Run 'nvim' to trigger LazyVim bootstrap and install plugins."
    else
        echo "Skipping Neovim config."
    fi
fi

print_summary

echo ""
echo -e "${GREEN}Theme setup complete.${NC}"
echo "GTK: $GTK_THEME | Icons: $ICON_THEME | Cursor: $CURSOR_THEME"
echo ""
echo "Run 'nwg-look' to fine-tune GTK settings visually."
echo "Restart Hyprland or re-login to apply all changes."
