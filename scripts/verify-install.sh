#!/bin/bash
# verify-install.sh — Diagnose Sway installation without modifying anything
# Exit 0: all checks pass. Exit 1: one or more checks failed.

source "$(dirname "$0")/common_functions.sh"

PASS=0
FAIL=0

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; ((PASS++)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; }
section() { echo ""; echo -e "${YELLOW}── $1 ──${NC}"; }

echo -e "${GREEN}=== Sway Installation Verifier ===${NC}"
echo "Read-only diagnostic — no changes made."

# ─── BINARIES ─────────────────────────────────────────────────────────────────
section "Core binaries"

REQUIRED_BINS=(
    "sway:sway"
    "hyprlock:hyprlock"
    "swayidle:swayidle"
    "waybar:waybar"
    "mako:mako-notifier"
    "wofi:wofi"
    "kitty:kitty"
    "grim:grim"
    "slurp:slurp"
    "wl-copy:wl-clipboard"
    "cliphist:cliphist"
    "pamixer:pamixer"
    "brightnessctl:brightnessctl"
    "playerctl:playerctl"
    "pipewire:pipewire"
    "wireplumber:wireplumber"
    "iwctl:iwd"
    "kanshi:kanshi"
    "wf-recorder:wf-recorder"
)

for entry in "${REQUIRED_BINS[@]}"; do
    bin="${entry%%:*}"
    pkg="${entry##*:}"
    if command -v "$bin" &>/dev/null; then
        pass "$bin"
    else
        fail "$bin (package: $pkg)"
    fi
done

section "Optional tools"

OPTIONAL_BINS=(
    "mpv:mpv"
    "nvim:neovim"
    "tmux:tmux"
    "flatpak:flatpak"
    "nwg-look:nwg-look"
    "qt5ct:qt5ct"
)

for entry in "${OPTIONAL_BINS[@]}"; do
    bin="${entry%%:*}"
    pkg="${entry##*:}"
    if command -v "$bin" &>/dev/null; then
        pass "$bin"
    else
        warn "$bin not found (optional, package: $pkg)"
    fi
done

# ─── SYSTEMD SERVICES ─────────────────────────────────────────────────────────
section "Systemd services (enabled)"

REQUIRED_SERVICES=(iwd bluetooth avahi-daemon)

for svc in "${REQUIRED_SERVICES[@]}"; do
    if systemctl is-enabled "$svc" &>/dev/null; then
        pass "systemctl: $svc"
    else
        fail "systemctl: $svc (not enabled)"
    fi
done

# ─── CONFIG FILES ─────────────────────────────────────────────────────────────
section "Configuration files"

CONFIG_FILES=(
    "$HOME/.config/sway/config"
    "$HOME/.config/hypr/hyprlock.conf"
    "$HOME/.config/waybar/config"
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/kanshi/config"
    "$HOME/.local/bin/check-updates.sh"
    "$HOME/.local/bin/install-github-bins.sh"
)

for f in "${CONFIG_FILES[@]}"; do
    if [ -f "$f" ]; then
        pass "$f"
    else
        fail "$f (missing — run setup-sway-config.sh)"
    fi
done

# ─── WAYLAND PURITY ───────────────────────────────────────────────────────────
section "Wayland purity"

if pgrep -x "Xorg" &>/dev/null || pgrep -x "X" &>/dev/null; then
    fail "Xorg process running — not pure Wayland"
else
    pass "No Xorg process running"
fi

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    pass "WAYLAND_DISPLAY is set ($WAYLAND_DISPLAY)"
else
    warn "WAYLAND_DISPLAY not set (expected if not inside a Sway session)"
fi

if [ -n "${SWAYSOCK:-}" ]; then
    pass "Sway session active (SWAYSOCK set)"
else
    warn "Not inside a Sway session — some checks skipped"
fi

# ─── APT SOURCES ──────────────────────────────────────────────────────────────
section "APT sources"

if [ -f /etc/apt/sources.list.d/sid.list ]; then
    warn "Sid sources present — not needed for Sway (can be removed)"
else
    pass "No Sid sources — pure Debian Testing"
fi

# ─── SUMMARY ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}══════════════════════════════${NC}"
echo -e "  Results: ${GREEN}$PASS passed${NC}  ${RED}$FAIL failed${NC}"
echo -e "${YELLOW}══════════════════════════════${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some checks failed. Review the output above.${NC}"
    echo "Common fixes:"
    echo "  Missing binaries:  bash scripts/install-sway.sh"
    echo "  Missing configs:   bash scripts/setup-sway-config.sh"
    exit 1
else
    echo -e "${GREEN}All required checks passed.${NC}"
    exit 0
fi
