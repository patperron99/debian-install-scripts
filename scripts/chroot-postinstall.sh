#!/bin/bash
# Hyprland postinstall orchestrator — chroot-safe
# Called from chroot_setup.sh after user creation.
# $1: USERNAME (non-root user created during chroot_setup.sh)

set -uo pipefail

USERNAME="${1:?chroot-postinstall.sh requires USERNAME as first argument}"
INSTALL_HOME="/home/$USERNAME"
REPO_DIR="/opt/debian-install-scripts"
SCRIPTS_DIR="$REPO_DIR/scripts"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

section() {
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}══════════════════════════════════════════${NC}"
    echo ""
}

# Step 1: Core Hyprland packages (apt as root — no sudo needed in chroot)
section "1/6 — Core + Hyprland packages"
bash "$SCRIPTS_DIR/install-hyprland.sh" "$USERNAME"

# Step 2: Configuration files (user context — runuser sets HOME correctly)
section "2/6 — Deploy configuration files"
runuser -l "$USERNAME" -c "cd '$REPO_DIR' && bash '$SCRIPTS_DIR/setup-hyprland-config.sh'"

# Step 3: Extras — dev tools, nerd fonts, TPM (mixed root/user)
section "3/6 — Extras (neovim, tmux, fonts, flatpak)"
bash "$SCRIPTS_DIR/install-extras-hyprland.sh" "$USERNAME"

# Step 4: Theme — GTK, icons, cursor, Neovim (interactive, user context)
section "4/6 — Theme (GTK, icons, cursor, Neovim)"
runuser -l "$USERNAME" -c "cd '$REPO_DIR' && bash '$SCRIPTS_DIR/setup-theme.sh'"

# Step 5: Lock screen — hyprlock + hypridle config files (user context)
section "5/6 — Lock screen (hyprlock + hypridle)"
runuser -l "$USERNAME" -c "cd '$REPO_DIR' && bash '$SCRIPTS_DIR/setup-hyprlock.sh'"

# Step 6: Wallpapers — download only; interactive selection deferred
section "6/6 — Wallpapers (download)"
runuser -l "$USERNAME" -c "cd '$REPO_DIR' && bash '$SCRIPTS_DIR/fetch-wallpapers.sh'" || true
echo -e "${YELLOW}[DEFERRED] Interactive wallpaper selection requires a running Wayland session.${NC}"
echo "  After first login: bash $SCRIPTS_DIR/setup-wallpaper.sh"

# ─── Systemd user units: write to disk now, enable at first login ─────────────
section "Systemd user timer (written to disk)"

USER_SYSTEMD_DIR="$INSTALL_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

HELPER="$INSTALL_HOME/.local/bin/check-updates.sh"

cat > "$USER_SYSTEMD_DIR/check-updates.service" << EOF
[Unit]
Description=Check for APT and Flatpak updates (Waybar module)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$HELPER
EOF

cat > "$USER_SYSTEMD_DIR/check-updates.timer" << 'TIMEREOF'
[Unit]
Description=Daily update check timer

[Timer]
OnBootSec=5min
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
TIMEREOF

chown -R "$USERNAME:$USERNAME" "$USER_SYSTEMD_DIR"

# Enable linger so user services start without an interactive login
loginctl enable-linger "$USERNAME" 2>/dev/null || true

# One-shot .bashrc snippet: enables the timer on first interactive login, then removes itself
BASHRC="$INSTALL_HOME/.bashrc"
cat >> "$BASHRC" << 'FIRSTLOGINEOF'

# ── First-login: enable systemd user timer ────────────────────────────────────
if [ -f "$HOME/.config/systemd/user/check-updates.timer" ] && \
   ! systemctl --user is-enabled check-updates.timer &>/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now check-updates.timer 2>/dev/null || true
    sed -i '/# ── First-login: enable systemd user timer/,/^fi$/d' "$HOME/.bashrc"
fi
# ─────────────────────────────────────────────────────────────────────────────
FIRSTLOGINEOF

chown "$USERNAME:$USERNAME" "$BASHRC"

# ─── Deferred steps ───────────────────────────────────────────────────────────
echo ""
echo -e "${YELLOW}[DEFERRED] The following require a running Hyprland session — run after first login:${NC}"
echo "  Multi-monitor:  bash $SCRIPTS_DIR/setup-multimonitor.sh"
echo "  Wallpaper pick: bash $SCRIPTS_DIR/setup-wallpaper.sh"
echo "  Zen browser:    flatpak install -y flathub app.zen_browser.zen"

section "Postinstall complete"
echo "Hyprland configured for user: $USERNAME"
echo "Reboot and select 'Hyprland' at the SDDM login screen."
