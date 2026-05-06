#!/bin/bash
# theme-picker.sh — Live theme switcher via wofi
# Installed to ~/.local/bin/theme-picker.sh by setup-sway-config.sh
# Bound to SUPER+SHIFT+T in sway config

SWAY_CONF="$HOME/.config/sway/config"
GTK3_CONF="$HOME/.config/gtk-3.0/settings.ini"
GTK4_CONF="$HOME/.config/gtk-4.0/settings.ini"
ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
NVIM_CS_FILE="$HOME/.config/nvim/lua/plugins/colorscheme.lua"
WALLPAPER_THEMES_DIR="$HOME/Pictures/Wallpapers/themes"

# ── Theme definitions ────────────────────────────────────────────────────────
# Format: name|border_active|border_inactive|gtk_theme|alacritty_palette|nvim_cs
declare -A THEMES
THEMES=(
    ["Catppuccin Mocha"]="rgba(cba6f7ee) rgba(89dcebee) 45deg|rgba(585b70aa)|Adwaita:dark|catppuccin-mocha|catppuccin"
    ["Tokyo Night"]="rgba(7aa2f7ee) rgba(bb9af7ee) 45deg|rgba(414868aa)|Adwaita:dark|tokyo-night|tokyonight-night"
    ["Gruvbox Dark"]="rgba(d79921ee) rgba(689d6aee) 45deg|rgba(504945aa)|Adwaita:dark|gruvbox-dark|gruvbox"
    ["Nord"]="rgba(88c0d0ee) rgba(81a1c1ee) 45deg|rgba(4c566aaa)|Adwaita:dark|nord|nord"
    ["Rose Pine"]="rgba(c4a7e7ee) rgba(ebbcbaee) 45deg|rgba(403d52aa)|Adwaita:dark|rose-pine|rose-pine"
)

# ── Alacritty color palettes ──────────────────────────────────────────────────
apply_alacritty_theme() {
    local theme="$1"
    [ ! -f "$ALACRITTY_CONF" ] && return

    case "$theme" in
        catppuccin-mocha)
            cat > /tmp/alacritty-colors.toml << 'EOF'
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black   = "#45475a"
red     = "#f38ba8"
green   = "#a6e3a1"
yellow  = "#f9e2af"
blue    = "#89b4fa"
magenta = "#f5c2e7"
cyan    = "#94e2d5"
white   = "#bac2de"
EOF
            ;;
        tokyo-night)
            cat > /tmp/alacritty-colors.toml << 'EOF'
[colors.primary]
background = "#1a1b26"
foreground = "#c0caf5"

[colors.normal]
black   = "#15161e"
red     = "#f7768e"
green   = "#9ece6a"
yellow  = "#e0af68"
blue    = "#7aa2f7"
magenta = "#bb9af7"
cyan    = "#7dcfff"
white   = "#a9b1d6"
EOF
            ;;
        gruvbox-dark)
            cat > /tmp/alacritty-colors.toml << 'EOF'
[colors.primary]
background = "#282828"
foreground = "#ebdbb2"

[colors.normal]
black   = "#282828"
red     = "#cc241d"
green   = "#98971a"
yellow  = "#d79921"
blue    = "#458588"
magenta = "#b16286"
cyan    = "#689d6a"
white   = "#a89984"
EOF
            ;;
        nord)
            cat > /tmp/alacritty-colors.toml << 'EOF'
[colors.primary]
background = "#2e3440"
foreground = "#d8dee9"

[colors.normal]
black   = "#3b4252"
red     = "#bf616a"
green   = "#a3be8c"
yellow  = "#ebcb8b"
blue    = "#81a1c1"
magenta = "#b48ead"
cyan    = "#88c0d0"
white   = "#e5e9f0"
EOF
            ;;
        rose-pine)
            cat > /tmp/alacritty-colors.toml << 'EOF'
[colors.primary]
background = "#191724"
foreground = "#e0def4"

[colors.normal]
black   = "#26233a"
red     = "#eb6f92"
green   = "#31748f"
yellow  = "#f6c177"
blue    = "#9ccfd8"
magenta = "#c4a7e7"
cyan    = "#ebbcba"
white   = "#e0def4"
EOF
            ;;
    esac

    # Remove existing [colors.*] blocks and append new palette
    if grep -q '\[colors' "$ALACRITTY_CONF"; then
        python3 -c "
import re, sys
content = open('$ALACRITTY_CONF').read()
content = re.sub(r'\n\[colors[^\[]*', '', content, flags=re.DOTALL)
content = re.sub(r'\n{3,}', '\n\n', content).rstrip()
open('$ALACRITTY_CONF', 'w').write(content + '\n')
" 2>/dev/null || true
    fi
    cat /tmp/alacritty-colors.toml >> "$ALACRITTY_CONF"
}

# ── GTK theme ────────────────────────────────────────────────────────────────
apply_gtk_theme() {
    local gtk_theme="$1"
    for conf in "$GTK3_CONF" "$GTK4_CONF"; do
        [ -f "$conf" ] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$conf"
    done
    command -v gsettings &>/dev/null && gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
}

# ── Sway borders ─────────────────────────────────────────────────────────────
apply_sway_theme() {
    local active="$1"
    local inactive="$2"
    if [ -f "$SWAY_CONF" ]; then
        sed -i \
            -e "s|client.focused .*|client.focused          $active $active #ffffff $active $active|" \
            -e "s|client.unfocused .*|client.unfocused        $inactive $inactive #888888 $inactive $inactive|" \
            -e "s|client.focused_inactive .*|client.focused_inactive $inactive $inactive #888888 $inactive $inactive|" \
            "$SWAY_CONF"
        command -v swaymsg &>/dev/null && swaymsg reload 2>/dev/null || true
    fi
}

# ── Waybar colors ─────────────────────────────────────────────────────────────
apply_waybar_theme() {
    local theme="$1"
    local css=""

    case "$theme" in
        "Catppuccin Mocha")
            css='/* Catppuccin Mocha */
@define-color fg               #cdd6f4;
@define-color fg_bright        #cdd6f4;
@define-color border           #585b70;
@define-color ws_active_bg     #1e1e2e;
@define-color ws_active_fg     #89b4fa;
@define-color ws_active_border #cba6f7;
@define-color urgent           #f38ba8;
@define-color urgent_text      #1e1e2e;
@define-color tray_bg          #181825;
@define-color tray_border      #a6e3a1;
@define-color separator        #89b4fa;
@define-color updates_ok       #a6e3a1;
@define-color updates_avail    #f38ba8;
@define-color window_border    #89dceb;'
            ;;
        "Tokyo Night")
            css='/* Tokyo Night */
@define-color fg               #a9b1d6;
@define-color fg_bright        #c0caf5;
@define-color border           #414868;
@define-color ws_active_bg     #1a1b26;
@define-color ws_active_fg     #7aa2f7;
@define-color ws_active_border #bb9af7;
@define-color urgent           #f7768e;
@define-color urgent_text      #15161e;
@define-color tray_bg          #24283b;
@define-color tray_border      #9ece6a;
@define-color separator        #7aa2f7;
@define-color updates_ok       #9ece6a;
@define-color updates_avail    #f7768e;
@define-color window_border    #7dcfff;'
            ;;
        "Gruvbox Dark")
            css='/* Gruvbox Dark */
@define-color fg               #ebdbb2;
@define-color fg_bright        #fbf1c7;
@define-color border           #504945;
@define-color ws_active_bg     #282828;
@define-color ws_active_fg     #458588;
@define-color ws_active_border #d79921;
@define-color urgent           #cc241d;
@define-color urgent_text      #fbf1c7;
@define-color tray_bg          #3c3836;
@define-color tray_border      #98971a;
@define-color separator        #458588;
@define-color updates_ok       #98971a;
@define-color updates_avail    #cc241d;
@define-color window_border    #689d6a;'
            ;;
        "Nord")
            css='/* Nord */
@define-color fg               #D8DEE9;
@define-color fg_bright        #eceff4;
@define-color border           #4c566a;
@define-color ws_active_bg     #2e3440;
@define-color ws_active_fg     #5e81ac;
@define-color ws_active_border #d08770;
@define-color urgent           #BF616A;
@define-color urgent_text      #2E3440;
@define-color tray_bg          #3b4252;
@define-color tray_border      #a3be8c;
@define-color separator        #5E81AC;
@define-color updates_ok       #A3BE8C;
@define-color updates_avail    #BF616A;
@define-color window_border    #88c0d0;'
            ;;
        "Rose Pine")
            css='/* Rose Pine */
@define-color fg               #e0def4;
@define-color fg_bright        #e0def4;
@define-color border           #403d52;
@define-color ws_active_bg     #191724;
@define-color ws_active_fg     #9ccfd8;
@define-color ws_active_border #c4a7e7;
@define-color urgent           #eb6f92;
@define-color urgent_text      #191724;
@define-color tray_bg          #26233a;
@define-color tray_border      #31748f;
@define-color separator        #9ccfd8;
@define-color updates_ok       #31748f;
@define-color updates_avail    #eb6f92;
@define-color window_border    #ebbcba;'
            ;;
        *) return ;;
    esac

    printf '%s\n' "$css" > "$WAYBAR_COLORS"
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    setsid waybar >/dev/null 2>&1 &
}

# ── Wallpaper ────────────────────────────────────────────────────────────────
apply_wallpaper_theme() {
    local theme="$1"
    local slug=""
    case "$theme" in
        "Catppuccin Mocha") slug="catppuccin-mocha" ;;
        "Tokyo Night")      slug="tokyo-night" ;;
        "Gruvbox Dark")     slug="gruvbox-dark" ;;
        "Nord")             slug="nord" ;;
        "Rose Pine")        slug="rose-pine" ;;
        *) return ;;
    esac

    local wallpaper=""
    for ext in jpg jpeg png webp; do
        if [ -f "$WALLPAPER_THEMES_DIR/$slug.$ext" ]; then
            wallpaper="$WALLPAPER_THEMES_DIR/$slug.$ext"
            break
        fi
    done
    [ -z "$wallpaper" ] && return

    pkill swaybg 2>/dev/null || true
    sleep 0.2
    swaybg -i "$wallpaper" -m fill &
    disown

    if [ -f "$AUTOSTART_CONF" ]; then
        sed -i "s|exec-once = swaybg.*|exec-once = swaybg -i $wallpaper -m fill|" "$AUTOSTART_CONF"
    fi
}

# ── Neovim colorscheme (LazyVim format) ──────────────────────────────────────
apply_neovim_theme() {
    local theme="$1"
    [ -d "$(dirname "$NVIM_CS_FILE")" ] || return

    local lua=""
    case "$theme" in
        "Catppuccin Mocha")
            lua='return {
    { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "mocha" } },
    { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}'
            ;;
        "Tokyo Night")
            lua='return {
    { "folke/tokyonight.nvim", opts = { style = "night" } },
    { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}'
            ;;
        "Gruvbox Dark")
            lua='return {
    { "ellisonleao/gruvbox.nvim" },
    { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}'
            ;;
        "Nord")
            lua='return {
    { "shaunsingh/nord.nvim" },
    { "LazyVim/LazyVim", opts = { colorscheme = "nord" } },
}'
            ;;
        "Rose Pine")
            lua='return {
    { "rose-pine/neovim", name = "rose-pine" },
    { "LazyVim/LazyVim", opts = { colorscheme = "rose-pine" } },
}'
            ;;
        *) return ;;
    esac

    printf '%s\n' "$lua" > "$NVIM_CS_FILE"
}

# ── Main ─────────────────────────────────────────────────────────────────────
CHOICE=$(printf '%s\n' "${!THEMES[@]}" | sort | wofi \
    --dmenu \
    --prompt "Theme" \
    --width 300 \
    --height 280 \
    --no-actions \
    --insensitive)

[ -z "$CHOICE" ] && exit 0

THEME_DATA="${THEMES[$CHOICE]}"
ACTIVE_BORDER=$(echo "$THEME_DATA" | cut -d'|' -f1)
INACTIVE_BORDER=$(echo "$THEME_DATA" | cut -d'|' -f2)
GTK_THEME=$(echo "$THEME_DATA" | cut -d'|' -f3)
ALACRITTY_PALETTE=$(echo "$THEME_DATA" | cut -d'|' -f4)
NVIM_CS=$(echo "$THEME_DATA" | cut -d'|' -f5)

apply_sway_theme "$ACTIVE_BORDER" "$INACTIVE_BORDER"
apply_gtk_theme "$GTK_THEME"
apply_alacritty_theme "$ALACRITTY_PALETTE"
apply_waybar_theme "$CHOICE"
apply_neovim_theme "$CHOICE"
apply_wallpaper_theme "$CHOICE"

notify-send "Theme" "Applied: $CHOICE" 2>/dev/null || true
