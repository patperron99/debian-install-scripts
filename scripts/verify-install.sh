#!/bin/bash
# verify-install.sh — Diagnose Hyprland installation without modifying anything
# Exit 0: all checks pass. Exit 1: one or more checks failed.

source "$(dirname "$0")/common_functions.sh"

PASS=0
FAIL=0

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; ((PASS++)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; ((FAIL++)); }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; }
section() { echo ""; echo -e "${YELLOW}── $1 ──${NC}"; }

echo -e "${GREEN}=== Hyprland Installation Verifier ===${NC}"
echo "Read-only diagnostic — no changes made."

# ─── BINARIES ─────────────────────────────────────────────────────────────────
section "Core binaries"

REQUIRED_BINS=(
    "Hyprland:hyprland"
    "waybar:waybar"
    "mako:mako"
    "wofi:wofi"
    "alacritty:alacritty"
    "grim:grim"
    "slurp:slurp"
    "wl-copy:wl-clipboard"
    "pamixer:pamixer"
    "brightnessctl:brightnessctl"
    "playerctl:playerctl"
    "sddm:sddm"
    "pipewire:pipewire"
    "wireplumber:wireplumber"
    "hyprpolkitagent:hyprpolkitagent"
    "iwctl:iwd"
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

section "Hyprland ecosystem"

ECOSYSTEM_BINS=(
    "hyprlock:hyprlock"
    "hypridle:hypridle"
    "swaybg:swaybg"
    "hyprpicker:hyprpicker"
    "cliphist:cliphist"
    "kanshi:kanshi"
    "swayosd-client:swayosd"
    "wf-recorder:wf-recorder"
)

for entry in "${ECOSYSTEM_BINS[@]}"; do
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

REQUIRED_SERVICES=(sddm iwd bluetooth acpid avahi-daemon)

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
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/.config/hypr/envs.conf"
    "$HOME/.config/hypr/bindings.conf"
    "$HOME/.config/hypr/autostart.conf"
    "$HOME/.config/hypr/hypridle.conf"
    "$HOME/.config/waybar/config"
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/kanshi/config"
    "$HOME/.local/bin/check-updates.sh"
)

for f in "${CONFIG_FILES[@]}"; do
    if [ -f "$f" ]; then
        pass "$f"
    else
        fail "$f (missing — run setup-hyprland-config.sh)"
    fi
done

# ─── WAYLAND PURITY ───────────────────────────────────────────────────────────
section "Wayland purity"

# Check for running Xorg processes (should be zero)
if pgrep -x "Xorg" &>/dev/null || pgrep -x "X" &>/dev/null; then
    fail "Xorg process running — not pure Wayland"
else
    pass "No Xorg process running"
fi

# Check WAYLAND_DISPLAY (only valid inside a Hyprland session)
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    pass "WAYLAND_DISPLAY is set ($WAYLAND_DISPLAY)"
else
    warn "WAYLAND_DISPLAY not set (expected if not inside a Hyprland session)"
fi

# Check HYPRLAND_INSTANCE_SIGNATURE (set by Hyprland for active session)
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    pass "Hyprland session active"
    # Check for any xwayland clients
    XWAYLAND_CLIENTS=$(hyprctl clients 2>/dev/null | grep -c "xwayland: 1" || echo "0")
    if [ "$XWAYLAND_CLIENTS" -eq 0 ]; then
        pass "No XWayland clients running"
    else
        warn "$XWAYLAND_CLIENTS XWayland client(s) running (not critical, but noted)"
    fi
else
    warn "Not inside a Hyprland session — some checks skipped"
fi

# ─── APT SOURCES ──────────────────────────────────────────────────────────────
section "APT sources"

if [ -f /etc/apt/sources.list.d/sid.list ]; then
    pass "Sid sources configured (/etc/apt/sources.list.d/sid.list)"
else
    warn "Sid sources not found — hyprland ecosystem may not be installable"
fi

if [ -f /etc/apt/preferences.d/sid-pin ]; then
    pass "APT pinning configured (/etc/apt/preferences.d/sid-pin)"
else
    warn "APT pinning not configured — Sid packages could pull unintended upgrades"
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
    echo "  Missing binaries:  bash scripts/install-hyprland.sh"
    echo "  Missing configs:   bash scripts/setup-hyprland-config.sh"
    echo "  Missing Sid pkgs:  ensure Sid sources are added"
    exit 1
else
    echo -e "${GREEN}All required checks passed.${NC}"
    exit 0
fi
