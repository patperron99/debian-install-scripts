#!/bin/bash
# setup-snapshot-boot.sh — Custom GRUB submenu for btrfs snapshots (APT-only, no grub-btrfs needed).
# Installs /etc/grub.d/41_snapshots and updates snapper-apt-post to call update-grub.

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== GRUB Snapshot Boot Setup ===${NC}"
echo ""

ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "btrfs" ]; then
    echo -e "${YELLOW}Root filesystem is '$ROOT_FS', not btrfs — skipping.${NC}"
    exit 0
fi

if ! command -v snapper &>/dev/null; then
    echo -e "${RED}snapper not found. Run setup-snapshots.sh first.${NC}"
    exit 1
fi

# --- GRUB script ---
sudo tee /etc/grub.d/41_snapshots > /dev/null << 'GRUBSCRIPT'
#!/bin/bash
# 41_snapshots — GRUB submenu for btrfs/snapper snapshots
# Boots the current kernel into a read-only snapshot root.
# For a permanent rollback use: sudo restore-snapshot

SNAPSHOTS_DIR="/.snapshots"
MAX_ENTRIES=20

findmnt -n -o FSTYPE / 2>/dev/null | grep -q btrfs || exit 0
[ -d "$SNAPSHOTS_DIR" ] || exit 0

SNAPS=$(ls -d "$SNAPSHOTS_DIR"/*/snapshot 2>/dev/null \
    | sed 's|.*/\([0-9]*\)/snapshot|\1|' | sort -rn | head -"$MAX_ENTRIES")
[ -z "$SNAPS" ] && exit 0

KERNEL=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
INITRD=$(ls /boot/initrd.img-* 2>/dev/null | sort -V | tail -1)
[ -z "$KERNEL" ] || [ -z "$INITRD" ] && exit 0

ROOT_UUID=$(findmnt -n -o UUID /)
# GRUB_CMDLINE_LINUX_DEFAULT / GRUB_CMDLINE_LINUX are exported by grub-mkconfig
CMDLINE="${GRUB_CMDLINE_LINUX_DEFAULT:-quiet} ${GRUB_CMDLINE_LINUX:-}"
# Strip any existing rootflags= — we set it per entry
CMDLINE=$(echo "$CMDLINE" | sed 's/rootflags=[^ ]*//g' | tr -s ' ' | xargs)

KERNEL_BASE=$(basename "$KERNEL")
INITRD_BASE=$(basename "$INITRD")

echo "submenu 'Btrfs snapshots' \$menuentry_id_option 'btrfs-snapshots' {"

for NUM in $SNAPS; do
    [ -d "$SNAPSHOTS_DIR/$NUM/snapshot" ] || continue

    INFO="$SNAPSHOTS_DIR/$NUM/info.xml"
    if [ -f "$INFO" ]; then
        DATE=$(sed -n 's|.*<date>\([^T]*\)T\([0-9:]*\).*</date>.*|\1 \2|p' "$INFO" | head -1)
        TYPE=$(sed -n 's|.*<type>\([^<]*\)</type>.*|\1|p' "$INFO" | head -1)
        DESC=$(sed -n 's|.*<description>\([^<]*\)</description>.*|\1|p' "$INFO" | head -1)
        LABEL="#${NUM}  ${DATE}  [${TYPE}] ${DESC}"
    else
        LABEL="Snapshot #${NUM}"
    fi

    cat <<EOF

  menuentry '${LABEL}' {
    search --no-floppy --fs-uuid --set=root ${ROOT_UUID}
    echo 'Loading snapshot ${NUM}...'
    linux   /boot/${KERNEL_BASE} root=UUID=${ROOT_UUID} rootflags=subvol=@snapshots/${NUM}/snapshot ${CMDLINE} ro
    initrd  /boot/${INITRD_BASE}
  }
EOF
done

echo "}"
GRUBSCRIPT

sudo chmod +x /etc/grub.d/41_snapshots
echo -e "${GREEN}Installed: /etc/grub.d/41_snapshots${NC}"

# --- Update snapper-apt-post to regenerate GRUB after each snapshot ---
# Only add update-grub if 41_snapshots is now in place (idempotent)
if [ -f /usr/local/bin/snapper-apt-post ]; then
    if ! grep -q 'update-grub' /usr/local/bin/snapper-apt-post; then
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
        echo -e "${GREEN}Updated: /usr/local/bin/snapper-apt-post (now regenerates GRUB)${NC}"
    else
        echo -e "${GREEN}snapper-apt-post already calls update-grub — skipping.${NC}"
    fi
else
    echo -e "${YELLOW}snapper-apt-post not found — run setup-snapshots.sh first, then re-run this script.${NC}"
fi

# --- Install restore-snapshot ---
RESTORE_SRC="$(dirname "$0")/restore-snapshot.sh"
if [ -f "$RESTORE_SRC" ]; then
    sudo install -m 755 "$RESTORE_SRC" /usr/local/bin/restore-snapshot
    echo -e "${GREEN}Installed: /usr/local/bin/restore-snapshot${NC}"
fi

# --- Regenerate GRUB ---
echo ""
echo "Regenerating GRUB config..."
sudo update-grub

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Snapshots appear in GRUB under 'Btrfs snapshots' (read-only — pour inspecter)."
echo "GRUB se régénère automatiquement après chaque apt upgrade."
echo ""
echo "Rollback permanent depuis le système en marche :"
echo "  sudo restore-snapshot"
