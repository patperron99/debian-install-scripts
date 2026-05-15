#!/bin/bash
set -uo pipefail

source scripts/common_functions.sh

# ─── HELPERS ──────────────────────────────────────────────────────────────────
section() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo ""
}

confirm_step() {
    local msg="$1"
    echo -e "${YELLOW}$msg (y/n)${NC}"
    local ans
    read -r ans
    while [[ ! "$ans" =~ ^[YyNn]$ ]]; do
        echo -e "${YELLOW}Please enter y or n:${NC}"
        read -r ans
    done
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ─── STEPS ────────────────────────────────────────────────────────────────────
step_packages() {
    section "1/8 — Core + Hyprland packages"
    bash scripts/install-hyprland.sh
}

step_configs() {
    section "2/8 — Deploy configuration files"
    bash scripts/setup-hyprland-config.sh
}

step_extras() {
    section "3/8 — Extras (neovim, tmux, fonts, wlogout)"
    bash scripts/install-extras-hyprland.sh
}

step_theme() {
    section "4/8 — Theme (GTK, cursor, Neovim)"
    bash scripts/setup-theme.sh
}

step_lockscreen() {
    section "5/8 — Lock screen (hyprlock + hypridle)"
    bash scripts/setup-hyprlock.sh
}

step_wallpaper() {
    section "6/8 — Wallpapers"
    bash scripts/fetch-wallpapers.sh
    bash scripts/setup-wallpaper.sh
}

step_updates() {
    section "7/8 — Auto-update timer"
    bash scripts/setup-auto-updates.sh
}

step_multimonitor() {
    section "8/8 — Multi-monitor layout"
    bash scripts/setup-multimonitor.sh
}

step_verify() {
    section "Verify installation"
    bash scripts/verify-install.sh
}

# ─── MENU ─────────────────────────────────────────────────────────────────────
show_menu() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Hyprland Post-Install Setup        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  a) Install everything (recommended)"
    echo "  ────────────────────────────────────"
    echo "  1) Core + Hyprland packages"
    echo "  2) Deploy configuration files"
    echo "  3) Extras  (neovim, tmux, fonts, wlogout)"
    echo "  4) Theme   (GTK, cursor, Neovim/LazyVim)"
    echo "  5) Lock screen  (hyprlock + hypridle)"
    echo "  6) Wallpapers"
    echo "  7) Auto-update timer"
    echo "  8) Multi-monitor layout"
    echo "  ────────────────────────────────────"
    echo "  9) Verify installation"
    echo "  q) Quit"
    echo ""
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Run from the repository root directory.${NC}"
echo -e "${YELLOW}Requires Debian Testing (Forky) or Sid.${NC}"

while true; do
    show_menu
    read -rp "Choice: " choice

    case "$choice" in
        a|A)
            step_packages
            step_configs
            step_extras
            step_theme
            step_lockscreen
            step_wallpaper
            step_updates
            if confirm_step "Configure multi-monitor layout?"; then
                step_multimonitor
            fi
            step_verify
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════${NC}"
            echo -e "${GREEN}  Setup complete. Reboot to start Hyprland.${NC}"
            echo -e "${GREEN}  At SDDM, select 'Hyprland'.              ${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════${NC}"
            echo ""
            break
            ;;
        1) step_packages ;;
        2) step_configs ;;
        3) step_extras ;;
        4) step_theme ;;
        5) step_lockscreen ;;
        6) step_wallpaper ;;
        7) step_updates ;;
        8) step_multimonitor ;;
        9) step_verify ;;
        q|Q)
            echo "Exiting."
            break
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Enter a, 1-9, or q.${NC}"
            ;;
    esac
done
