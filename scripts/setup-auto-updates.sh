#!/bin/bash
# setup-auto-updates.sh — Configure APT refresh timer + Waybar update module
# - System timer: daily apt-get update (root) to keep package lists fresh
# - APT hook: signals Waybar immediately after any apt/dpkg operation
# - User timer: belt-and-suspenders Waybar refresh signal

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Auto-Update Check Setup ===${NC}"
echo "Configures APT list refresh (system) + Waybar update count (user)."
echo "No automatic installation — updates are always interactive."
echo ""

SYSTEMD_DIR="$HOME/.config/systemd/user"

# --- APT HOOK: signal Waybar after apt update / dpkg operations ---
echo ""
echo "Installing APT hook to refresh Waybar on package changes..."

sudo tee /usr/local/bin/waybar-signal-updates > /dev/null << 'SCRIPT'
#!/bin/sh
pkill -RTMIN+8 waybar >/dev/null 2>&1
exit 0
SCRIPT
sudo chmod +x /usr/local/bin/waybar-signal-updates

sudo tee /etc/apt/apt.conf.d/81waybar-updates > /dev/null << 'EOF'
APT::Update::Post-Invoke { "sh -c '/usr/local/bin/waybar-signal-updates || true'"; };
DPkg::Post-Invoke { "sh -c '/usr/local/bin/waybar-signal-updates || true'"; };
EOF

echo -e "${GREEN}Installed: /etc/apt/apt.conf.d/81waybar-updates${NC}"

# --- SYSTEM TIMER: daily apt-get update to keep package lists fresh ---
echo ""
echo "Installing system timer for daily APT list refresh..."

sudo tee /etc/systemd/system/apt-refresh.service > /dev/null << 'EOF'
[Unit]
Description=Daily APT package list refresh
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/apt-get update -qq
EOF

sudo tee /etc/systemd/system/apt-refresh.timer > /dev/null << 'EOF'
[Unit]
Description=Daily APT package list refresh

[Timer]
OnCalendar=daily
RandomizedDelaySec=30min
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now apt-refresh.timer \
    && echo -e "${GREEN}Timer enabled: apt-refresh.timer (daily apt-get update)${NC}" \
    || echo -e "${YELLOW}Could not enable apt-refresh.timer — run: sudo systemctl enable --now apt-refresh.timer${NC}"

# --- SYSTEMD USER SERVICE: signal Waybar on timer tick ---
echo ""
echo "Creating systemd user units..."
mkdir -p "$SYSTEMD_DIR"

cat > "$SYSTEMD_DIR/check-updates.service" << 'EOF'
[Unit]
Description=Refresh Waybar update count

[Service]
Type=oneshot
ExecStart=/usr/bin/pkill -RTMIN+8 waybar
EOF

cat > "$SYSTEMD_DIR/check-updates.timer" << 'EOF'
[Unit]
Description=Periodic Waybar update count refresh

[Timer]
OnBootSec=5min
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo -e "${GREEN}Created: $SYSTEMD_DIR/check-updates.{service,timer}${NC}"

# --- ENABLE USER TIMER ---
echo ""
systemctl --user daemon-reload
systemctl --user enable --now check-updates.timer \
    && echo -e "${GREEN}Timer enabled: check-updates.timer${NC}" \
    || echo -e "${YELLOW}Could not enable timer — run manually after login: systemctl --user enable --now check-updates.timer${NC}"

echo ""
echo -e "${GREEN}=== Auto-update check configured ===${NC}"
echo ""
echo "Update flow:"
echo "  1. apt-refresh.timer runs apt-get update daily (system)"
echo "  2. APT hook signals Waybar immediately after any apt/dpkg operation"
echo "  3. Waybar re-runs check-updates.sh and shows fresh count"
echo ""
echo "  Green  = system up to date"
echo "  Orange = updates available (count shown)"
echo "  Click  = open terminal to apply updates interactively"
echo ""
echo "Manual trigger: sudo apt-get update  (APT hook signals Waybar automatically)"
