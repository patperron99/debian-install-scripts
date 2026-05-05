#!/bin/bash
# setup-auto-updates.sh — Configure systemd user timer for daily update checks
# Updates check-updates.sh to include Flatpak count alongside APT.

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Auto-Update Check Setup ===${NC}"
echo "Configures a daily systemd user timer that checks for APT and Flatpak updates."
echo "Results are shown as a Waybar icon — no automatic installation."
echo ""

HELPER="$HOME/.local/bin/check-updates.sh"
SYSTEMD_DIR="$HOME/.config/systemd/user"

# --- UPDATE check-updates.sh TO INCLUDE FLATPAK ---
echo "Installing updated check-updates.sh (APT + Flatpak)..."
mkdir -p "$HOME/.local/bin"

cat > "$HELPER" << 'HELPEREOF'
#!/bin/bash
# Waybar update module — emits JSON with APT + Flatpak update counts

APT_COUNT=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst" || echo "0")
APT_SECURITY=$(apt-get -s upgrade 2>/dev/null | grep -c "^Inst.*security" || echo "0")

if command -v flatpak &>/dev/null; then
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l || echo "0")
else
    FLATPAK_COUNT=0
fi

TOTAL=$((APT_COUNT + FLATPAK_COUNT))

if [ "$TOTAL" -eq 0 ]; then
    echo '{"text":" ","tooltip":"System up to date","class":"updated"}'
else
    TOOLTIP="${APT_COUNT} APT"
    [ "$APT_SECURITY" -gt 0 ] && TOOLTIP+=" (${APT_SECURITY} security)"
    [ "$FLATPAK_COUNT" -gt 0 ] && TOOLTIP+=", ${FLATPAK_COUNT} Flatpak"
    TOOLTIP+=" updates available"
    echo "{\"text\":\" ${TOTAL}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"updates-available\"}"
fi
HELPEREOF

chmod +x "$HELPER"
echo -e "${GREEN}Updated: $HELPER${NC}"

# --- SYSTEMD USER SERVICE ---
echo ""
echo "Creating systemd user units..."
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/check-updates.service" << EOF
[Unit]
Description=Check for APT and Flatpak updates (Waybar module)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$HELPER
EOF

cat > "$SYSTEMD_DIR/check-updates.timer" << 'EOF'
[Unit]
Description=Daily update check timer

[Timer]
OnBootSec=5min
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo -e "${GREEN}Created: $SYSTEMD_DIR/check-updates.{service,timer}${NC}"

# --- ENABLE TIMER ---
echo ""
systemctl --user daemon-reload
systemctl --user enable --now check-updates.timer \
    && echo -e "${GREEN}Timer enabled: check-updates.timer (daily + 5min after boot)${NC}" \
    || echo -e "${YELLOW}Could not enable timer — run manually after login: systemctl --user enable --now check-updates.timer${NC}"

echo ""
echo -e "${GREEN}=== Auto-update check configured ===${NC}"
echo ""
echo "The Waybar icon updates automatically:"
echo "  Green  = system up to date"
echo "  Orange = updates available (count shown)"
echo "  Click  = open terminal to apply updates interactively"
echo ""
echo "Manual trigger: systemctl --user start check-updates.service"
