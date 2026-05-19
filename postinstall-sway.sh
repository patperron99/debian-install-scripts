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
    section "1/9 — Core + Sway packages"
    bash scripts/install-sway.sh
}

step_configs() {
    section "2/9 — Deploy configuration files"
    bash scripts/setup-sway-config.sh
}

step_extras() {
    section "3/9 — Extras (neovim, tmux, fonts, flatpak)"
    bash scripts/install-extras-sway.sh
}

step_theme() {
    section "4/9 — Theme (GTK, cursor, Neovim)"
    bash scripts/setup-theme.sh
}

step_wallpaper() {
    section "5/9 — Wallpapers"
    bash scripts/fetch-wallpapers.sh
    bash scripts/setup-wallpaper.sh
}

step_updates() {
    section "6/9 — Auto-update timer"
    bash scripts/setup-auto-updates.sh
}

step_snapshots() {
    section "7/9 — BTRFS snapshots + GRUB boot entries"
    bash scripts/setup-snapshots.sh
    bash scripts/setup-snapshot-boot.sh
}

step_plymouth() {
    section "8/9 — Plymouth boot splash screen"
    bash scripts/setup-plymouth.sh
}

step_multimonitor() {
    section "9/9 — Multi-monitor layout"
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
    echo -e "${GREEN}║         Sway Post-Install Setup          ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo "  a) Install everything (recommended)"
    echo "  ────────────────────────────────────"
    echo "  1) Core + Sway packages"
    echo "  2) Deploy configuration files"
    echo "  3) Extras  (neovim, tmux, fonts, flatpak)"
    echo "  4) Theme   (GTK, cursor, Neovim/LazyVim)"
    echo "  5) Wallpapers"
    echo "  6) Auto-update timer"
    echo "  7) BTRFS snapshots + GRUB boot entries"
    echo "  8) Plymouth boot splash screen"
    echo "  9) Multi-monitor layout"
    echo "  ────────────────────────────────────"
    echo "  10) Verify installation"
    echo "  q) Quit"
    echo ""
}

# ─── MAIN ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}Run from the repository root directory.${NC}"
echo -e "${YELLOW}Requires Debian Testing (Forky). Run from the cloned repository root.${NC}"

while true; do
    show_menu
    read -rp "Choice: " choice

    case "$choice" in
        a|A)
            step_packages
            step_configs
            step_extras
            step_theme
            step_wallpaper
            step_updates
            step_snapshots
            step_plymouth
            if confirm_step "Configure multi-monitor layout?"; then
                step_multimonitor
            fi
            step_verify
            echo ""
            echo -e "${GREEN}═══════════════════════════════════════════${NC}"
            echo -e "${GREEN}  Setup complete. Reboot to start Sway.    ${NC}"
            echo -e "${GREEN}  Autologin on TTY1 — Sway starts automatically.${NC}"
            echo -e "${GREEN}═══════════════════════════════════════════${NC}"
            echo ""
            break
            ;;
        1) step_packages ;;
        2) step_configs ;;
        3) step_extras ;;
        4) step_theme ;;
        5) step_wallpaper ;;
        6) step_updates ;;
        7) step_snapshots ;;
        8) step_plymouth ;;
        9) step_multimonitor ;;
        10) step_verify ;;
        q|Q)
            echo "Exiting."
            break
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Enter a, 1-10, or q.${NC}"
            ;;
    esac
done
