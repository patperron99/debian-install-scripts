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

# ── Theme definitions ────────────────────────────────────────────────────────
# Format: name|border_active|border_inactive|gtk_theme|alacritty_slug|nvim_cs
declare -A THEMES
THEMES=(
    ["Catppuccin Mocha"]="#cba6f7|#585b70|Adwaita:dark|catppuccin-mocha|catppuccin"
    ["Tokyo Night"]="#7aa2f7|#414868|Adwaita:dark|tokyo-night|tokyonight-night"
    ["Gruvbox Dark"]="#d79921|#504945|Adwaita:dark|gruvbox-dark|gruvbox"
    ["Nord"]="#88c0d0|#4c566a|Adwaita:dark|nord|nord"
    ["Rose Pine"]="#c4a7e7|#403d52|Adwaita:dark|rose-pine|rose-pine"
)

# ── Alacritty theme (via import file) ────────────────────────────────────────
apply_alacritty_theme() {
    local theme_slug="$1"
    local src="$HOME/.config/alacritty/themes/${theme_slug}.toml"
    local dst="$HOME/.config/alacritty/themes/current-theme.toml"
    [ -f "$src" ] && cp "$src" "$dst"
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
@define-color bg               #1e1e2e;
@define-color bg1              #181825;
@define-color fg               #cdd6f4;
@define-color fg_bright        #cdd6f4;
@define-color border           #585b70;
@define-color ws_active_bg     #313244;
@define-color ws_active_fg     #cba6f7;
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
@define-color bg               #1a1b26;
@define-color bg1              #24283b;
@define-color fg               #a9b1d6;
@define-color fg_bright        #c0caf5;
@define-color border           #414868;
@define-color ws_active_bg     #292e42;
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
@define-color bg               #282828;
@define-color bg1              #3c3836;
@define-color fg               #ebdbb2;
@define-color fg_bright        #fbf1c7;
@define-color border           #504945;
@define-color ws_active_bg     #3c3836;
@define-color ws_active_fg     #fabd2f;
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
@define-color bg               #2e3440;
@define-color bg1              #3b4252;
@define-color fg               #d8dee9;
@define-color fg_bright        #eceff4;
@define-color border           #4c566a;
@define-color ws_active_bg     #3b4252;
@define-color ws_active_fg     #88c0d0;
@define-color ws_active_border #d08770;
@define-color urgent           #bf616a;
@define-color urgent_text      #2e3440;
@define-color tray_bg          #3b4252;
@define-color tray_border      #a3be8c;
@define-color separator        #5e81ac;
@define-color updates_ok       #a3be8c;
@define-color updates_avail    #bf616a;
@define-color window_border    #88c0d0;'
            ;;
        "Rose Pine")
            css='/* Rose Pine */
@define-color bg               #191724;
@define-color bg1              #26233a;
@define-color fg               #e0def4;
@define-color fg_bright        #e0def4;
@define-color border           #403d52;
@define-color ws_active_bg     #26233a;
@define-color ws_active_fg     #c4a7e7;
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
        "Gruvbox Dark")     slug="gruvbox" ;;
        "Nord")             slug="nord" ;;
        "Rose Pine")        slug="rose-pine" ;;
        *) return ;;
    esac

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

# ── Mako notification colors ─────────────────────────────────────────────────
apply_mako_theme() {
    local theme="$1"
    local mako_conf="$HOME/.config/mako/config"
    [ -d "$(dirname "$mako_conf")" ] || return

    local bg text border border_low border_normal border_high bg_high
    case "$theme" in
        "Catppuccin Mocha")
            bg="#1e1e2e"; text="#cdd6f4"; border="#89b4fa"
            border_low="#a6e3a1"; border_normal="#89b4fa"; border_high="#f38ba8"; bg_high="#45085a" ;;
        "Tokyo Night")
            bg="#1a1b26"; text="#a9b1d6"; border="#7aa2f7"
            border_low="#9ece6a"; border_normal="#7aa2f7"; border_high="#f7768e"; bg_high="#24283b" ;;
        "Gruvbox Dark")
            bg="#282828"; text="#ebdbb2"; border="#d79921"
            border_low="#98971a"; border_normal="#458588"; border_high="#cc241d"; bg_high="#3c3836" ;;
        "Nord")
            bg="#2e3440"; text="#d8dee9"; border="#5e81ac"
            border_low="#a3be8c"; border_normal="#5e81ac"; border_high="#bf616a"; bg_high="#3b4252" ;;
        "Rose Pine")
            bg="#191724"; text="#e0def4"; border="#c4a7e7"
            border_low="#31748f"; border_normal="#9ccfd8"; border_high="#eb6f92"; bg_high="#26233a" ;;
        *) return ;;
    esac

    cat > "$mako_conf" << EOF
# Mako notification daemon configuration
# Managed by theme-picker.sh — do not edit colors manually

default-timeout=5000
ignore-timeout=0

max-visible=5
sort=-time

layer=overlay
anchor=top-right
margin=10
padding=10
border-size=2
border-radius=8
font=monospace 11
width=300
height=100

background-color=$bg
text-color=$text
border-color=$border
progress-color=over $bg

[urgency=low]
default-timeout=3000
border-color=$border_low

[urgency=normal]
default-timeout=5000
border-color=$border_normal

[urgency=high]
default-timeout=0
border-color=$border_high
background-color=$bg_high
EOF

    pkill -x mako 2>/dev/null || true
    sleep 0.2
    setsid mako >/dev/null 2>&1 &
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
apply_mako_theme "$CHOICE"
apply_neovim_theme "$CHOICE"
apply_wallpaper_theme "$CHOICE"

notify-send "Theme" "Applied: $CHOICE" 2>/dev/null || true
