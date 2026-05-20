#!/bin/bash
# theme-picker.sh — Live theme switcher via wofi
# Installed to ~/.local/bin/theme-picker.sh by setup-sway-config.sh
# Bound to SUPER+SHIFT+T in sway config
#
# Architecture:
#   configs/themes/<slug>.sh  — color variables per theme (edit here to tune colors)
#   configs/tmux/theme.tmpl   — tmux status format    (edit here to change layout)
#   configs/waybar/colors.tmpl — waybar CSS colors     (edit here to add/rename vars)
#   configs/mako/config.tmpl  — mako notification config
# theme-picker sources the theme file, exports vars, then envsubst fills templates.

SWAY_CONF="$HOME/.config/sway/config"
GTK3_CONF="$HOME/.config/gtk-3.0/settings.ini"
GTK4_CONF="$HOME/.config/gtk-4.0/settings.ini"
WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
NVIM_CS_FILE="$HOME/.config/nvim/lua/plugins/colorscheme.lua"

THEMES_DIR="$HOME/.config/themes"
TMUX_TMPL="$HOME/.config/tmux/theme.tmpl"
WAYBAR_TMPL="$HOME/.config/waybar/colors.tmpl"
MAKO_TMPL="$HOME/.config/mako/config.tmpl"

# Display name → theme slug
declare -A THEME_SLUGS
THEME_SLUGS=(
    ["Catppuccin Mocha"]="catppuccin-mocha"
    ["Tokyo Night"]="tokyo-night"
    ["Gruvbox Dark"]="gruvbox"
    ["Nord"]="nord"
    ["Rose Pine"]="rose-pine"
)

# ── Sway borders ─────────────────────────────────────────────────────────────
apply_sway_theme() {
    [ -f "$SWAY_CONF" ] || return
    sed -i \
        -e "s|client.focused .*|client.focused          $BORDER_ACTIVE $BORDER_ACTIVE #ffffff $BORDER_ACTIVE $BORDER_ACTIVE|" \
        -e "s|client.unfocused .*|client.unfocused        $BORDER_INACTIVE $BORDER_INACTIVE #888888 $BORDER_INACTIVE $BORDER_INACTIVE|" \
        -e "s|client.focused_inactive .*|client.focused_inactive $BORDER_INACTIVE $BORDER_INACTIVE #888888 $BORDER_INACTIVE $BORDER_INACTIVE|" \
        "$SWAY_CONF"
    command -v swaymsg &>/dev/null && swaymsg reload 2>/dev/null || true
}

# ── GTK theme ────────────────────────────────────────────────────────────────
apply_gtk_theme() {
    for conf in "$GTK3_CONF" "$GTK4_CONF"; do
        [ -f "$conf" ] && sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$conf"
    done
    command -v gsettings &>/dev/null && \
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
}

# ── Kitty theme ──────────────────────────────────────────────────────────────
apply_kitty_theme() {
    local src="$HOME/.config/kitty/themes/${SLUG}.conf"
    local dst="$HOME/.config/kitty/current-theme.conf"
    [ -f "$src" ] && cp "$src" "$dst"
    pkill -SIGUSR1 kitty 2>/dev/null || true
}

# ── Waybar colors (from template) ────────────────────────────────────────────
apply_waybar_theme() {
    envsubst < "$WAYBAR_TMPL" > "$WAYBAR_COLORS"
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    setsid waybar >/dev/null 2>&1 &
}

# ── Mako notification config (from template) ─────────────────────────────────
apply_mako_theme() {
    envsubst < "$MAKO_TMPL" > "$HOME/.config/mako/config"
    makoctl reload 2>/dev/null || true
}

# ── Tmux powerline theme (from template) ─────────────────────────────────────
apply_tmux_theme() {
    local f="$HOME/.config/tmux/theme.conf"
    envsubst < "$TMUX_TMPL" > "$f"
    tmux source-file "$f" 2>/dev/null || true
}

# ── Neovim colorscheme (LazyVim format) ──────────────────────────────────────
apply_neovim_theme() {
    local slug="$1"
    [ -d "$(dirname "$NVIM_CS_FILE")" ] || return
    local lua
    case "$slug" in
        catppuccin-mocha)
            lua='return {
    { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "mocha" } },
    { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}' ;;
        tokyo-night)
            lua='return {
    { "folke/tokyonight.nvim", opts = { style = "night" } },
    { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
}' ;;
        gruvbox)
            lua='return {
    { "ellisonleao/gruvbox.nvim" },
    { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}' ;;
        nord)
            lua='return {
    { "shaunsingh/nord.nvim" },
    { "LazyVim/LazyVim", opts = { colorscheme = "nord" } },
}' ;;
        rose-pine)
            lua='return {
    { "rose-pine/neovim", name = "rose-pine" },
    { "LazyVim/LazyVim", opts = { colorscheme = "rose-pine" } },
}' ;;
        *) return ;;
    esac
    printf '%s\n' "$lua" > "$NVIM_CS_FILE"

    local cs_name lazy_plugin
    case "$slug" in
        catppuccin-mocha) cs_name="catppuccin";      lazy_plugin="catppuccin" ;;
        tokyo-night)      cs_name="tokyonight-night"; lazy_plugin="tokyonight.nvim" ;;
        gruvbox)          cs_name="gruvbox";          lazy_plugin="gruvbox.nvim" ;;
        nord)             cs_name="nord";             lazy_plugin="nord.nvim" ;;
        rose-pine)        cs_name="rose-pine";        lazy_plugin="rose-pine" ;;
        *) return ;;
    esac
    for sock in /tmp/nvim.*.0 /run/user/"$(id -u)"/nvim.*.0; do
        [ -S "$sock" ] || continue
        nvim --server "$sock" --remote-send ":Lazy load $lazy_plugin<CR>:colorscheme $cs_name<CR>" 2>/dev/null || true
    done
}

# ── Btop theme ───────────────────────────────────────────────────────────────
apply_btop_theme() {
    local slug="$1"
    local btop_conf="$HOME/.config/btop/btop.conf"
    [ -f "$btop_conf" ] || return
    local btop_theme
    case "$slug" in
        catppuccin-mocha) btop_theme="Default" ;;
        tokyo-night)      btop_theme="tokyo-night" ;;
        gruvbox)          btop_theme="gruvbox_dark_v2" ;;
        nord)             btop_theme="nord" ;;
        rose-pine)        btop_theme="Default" ;;
        *) return ;;
    esac
    sed -i "s|^color_theme = .*|color_theme = \"$btop_theme\"|" "$btop_conf"
}

# ── Wallpaper ────────────────────────────────────────────────────────────────
apply_wallpaper_theme() {
    local slug="$1"
    mkdir -p "$HOME/.local/share"
    echo "$slug" > "$HOME/.local/share/current-theme"

    local wallpaper_dir="$HOME/Pictures/Wallpapers/$slug"
    [ -d "$wallpaper_dir" ] || return

    readarray -t walls < <(find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)
    [ ${#walls[@]} -eq 0 ] && return

    local wallpaper="${walls[$(( RANDOM % ${#walls[@]} ))]}"
    swaymsg "output '*' bg $wallpaper fill" 2>/dev/null || \
        { pkill swaybg 2>/dev/null; sleep 0.2; swaybg -i "$wallpaper" -m fill & disown; }
    [ -f "$SWAY_CONF" ] && sed -i "s|output \* bg .*|output * bg $wallpaper fill|" "$SWAY_CONF"
}

# ── Main ─────────────────────────────────────────────────────────────────────
CHOICE=$(printf '%s\n' "${!THEME_SLUGS[@]}" | sort | wofi \
    --dmenu \
    --prompt "Theme" \
    --width 300 \
    --height 280 \
    --no-actions \
    --insensitive)

[ -z "$CHOICE" ] && exit 0

SLUG="${THEME_SLUGS[$CHOICE]}"
THEME_FILE="$THEMES_DIR/$SLUG.sh"

if [ ! -f "$THEME_FILE" ]; then
    notify-send "Theme" "Theme file not found: $THEME_FILE" 2>/dev/null || true
    exit 1
fi

# Source theme variables and auto-export all for envsubst
set -a
source "$THEME_FILE"
set +a

apply_sway_theme
apply_gtk_theme
apply_kitty_theme
apply_waybar_theme
apply_mako_theme
apply_tmux_theme
apply_neovim_theme "$SLUG"
apply_btop_theme "$SLUG"
apply_wallpaper_theme "$SLUG"

notify-send "Theme" "Applied: $CHOICE" 2>/dev/null || true
