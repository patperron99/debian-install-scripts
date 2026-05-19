#!/bin/bash
# setup-snapshots.sh — Configure snapper for automatic BTRFS snapshots
# Creates pre/post snapshots around every apt/dpkg operation.

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== BTRFS Snapshot Setup (snapper) ===${NC}"
echo ""

# --- GUARD: require BTRFS root ---
ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "btrfs" ]; then
    echo -e "${YELLOW}Root filesystem is '$ROOT_FS', not btrfs.${NC}"
    echo "Snapper requires a Btrfs root. Skipping."
    exit 0
fi

# --- INSTALL snapper ---
echo "Installing snapper..."
if ! check_package "snapper"; then
    echo -e "${RED}snapper not found in APT repositories.${NC}"
    exit 1
fi
install_package "snapper"
install_package "snapper-gui" 2>/dev/null || true  # optional GUI

# --- CREATE CONFIGS ---
echo ""
echo "Creating snapper configurations..."

SNAPPER_TEMPLATE="/usr/share/snapper/config-templates/default"

create_snapper_config() {
    local config="$1"   # e.g. "root"
    local subvol="$2"   # e.g. "/"

    if snapper list-configs 2>/dev/null | grep -q "^${config}"; then
        echo -e "${YELLOW}Snapper config '${config}' already exists — skipping.${NC}"
        return 0
    fi

    # Try normal path first; if .snapshots subvolume already exists snapper
    # will refuse to create it — fall back to copying the template directly.
    if sudo snapper -c "$config" create-config "$subvol" 2>/dev/null; then
        echo -e "${GREEN}Created snapper config: ${config} (${subvol})${NC}"
    elif [ -f "$SNAPPER_TEMPLATE" ]; then
        echo -e "${YELLOW}.snapshots subvolume already exists — installing config from template.${NC}"
        sudo cp "$SNAPPER_TEMPLATE" "/etc/snapper/configs/${config}"
        sudo sed -i "s|^SUBVOLUME=.*|SUBVOLUME=\"${subvol}\"|" "/etc/snapper/configs/${config}"
        echo -e "${GREEN}Created snapper config: ${config} (${subvol})${NC}"
    else
        echo -e "${RED}Failed to create snapper config '${config}'.${NC}"
        return 1
    fi
}

# Root config
create_snapper_config "root" "/"

# Home config (only if /home is a separate btrfs subvolume)
HOME_FS=$(findmnt -n -o FSTYPE /home 2>/dev/null || echo "")
[ "$HOME_FS" = "btrfs" ] && create_snapper_config "home" "/home"

# --- RETENTION POLICY ---
echo ""
echo "Configuring retention policy..."

configure_retention() {
    local config="$1"
    local conf_file="/etc/snapper/configs/$config"

    if [ ! -f "$conf_file" ]; then
        echo -e "${YELLOW}Config file $conf_file not found — skipping retention config.${NC}"
        return
    fi

    sudo sed -i \
        -e 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="6"/' \
        -e 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' \
        -e 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="4"/' \
        -e 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="3"/' \
        -e 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' \
        -e 's/^TIMELINE_CREATE=.*/TIMELINE_CREATE="yes"/' \
        -e 's/^TIMELINE_CLEANUP=.*/TIMELINE_CLEANUP="yes"/' \
        "$conf_file"

    echo -e "${GREEN}Retention set for '$config': 6h / 7d / 4w / 3m${NC}"
}

configure_retention "root"
[ "$HOME_FS" = "btrfs" ] && configure_retention "home"

# --- APT HOOKS (pre/post snapshots around every dpkg run) ---
echo ""
echo "Installing APT snapshot hooks..."

# Write helper scripts so the APT config stays simple and parseable
sudo tee /usr/local/bin/snapper-apt-pre > /dev/null << 'SCRIPT'
#!/bin/sh
[ -x /usr/bin/snapper ] || exit 0
NUM=$(snapper -c root create --type pre --cleanup-algorithm number --print-number --description "apt" 2>/dev/null) || true
echo "$NUM" > /run/snapper-apt-pre-number
exit 0
SCRIPT
sudo chmod +x /usr/local/bin/snapper-apt-pre

sudo tee /usr/local/bin/snapper-apt-post > /dev/null << 'SCRIPT'
#!/bin/sh
[ -x /usr/bin/snapper ] || exit 0
PRE=$(cat /run/snapper-apt-pre-number 2>/dev/null) || exit 0
snapper -c root create --type post --cleanup-algorithm number --pre-number "$PRE" --description "apt" || true
rm -f /run/snapper-apt-pre-number
update-grub 2>/dev/null || true
exit 0
SCRIPT
sudo chmod +x /usr/local/bin/snapper-apt-post

# APT config — calls the scripts directly (no inline shell, exit 0 is in the scripts)
sudo tee /etc/apt/apt.conf.d/80snapper > /dev/null << 'EOF'
DPkg::Pre-Invoke  { "/usr/local/bin/snapper-apt-pre"; };
DPkg::Post-Invoke { "/usr/local/bin/snapper-apt-post"; };
EOF

echo -e "${GREEN}Installed: /etc/apt/apt.conf.d/80snapper${NC}"

# --- ENABLE SYSTEMD TIMERS ---
echo ""
echo "Enabling snapper systemd timers..."

sudo systemctl enable --now snapper-timeline.timer 2>/dev/null \
    && echo -e "${GREEN}Enabled: snapper-timeline.timer${NC}" \
    || echo -e "${YELLOW}snapper-timeline.timer not found (may not be installed yet)${NC}"

sudo systemctl enable --now snapper-cleanup.timer 2>/dev/null \
    && echo -e "${GREEN}Enabled: snapper-cleanup.timer${NC}" \
    || echo -e "${YELLOW}snapper-cleanup.timer not found${NC}"

# --- SUMMARY ---
echo ""
echo -e "${GREEN}=== Snapper Setup Complete ===${NC}"
echo ""
echo "Snapshots will be created automatically:"
echo "  - Before/after every apt/dpkg operation"
echo "  - On a timeline: hourly, daily, weekly, monthly"
echo ""
echo "Useful commands:"
echo "  snapper list                     # List all snapshots"
echo "  snapper status 1..3              # Changes between snapshots 1 and 3"
echo "  snapper undochange 1..3          # Undo changes between snapshots"
echo "  snapper delete 5                 # Delete snapshot 5"
