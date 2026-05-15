#!/bin/bash
# restore-snapshot.sh — Replace the @ subvolume with a chosen snapper snapshot.
# Strategy: mount btrfs root (subvolid=5), backup @, delete it, snapshot chosen → @, reboot.
# Safe to run from the live system — btrfs keeps the mounted @ alive until reboot.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "btrfs" ]; then
    echo -e "${RED}Root filesystem is not btrfs.${NC}"
    exit 1
fi

if ! command -v snapper &>/dev/null; then
    echo -e "${RED}snapper not found.${NC}"
    exit 1
fi

echo -e "${CYAN}=== Btrfs Snapshot Restore ===${NC}"
echo ""
echo "Available snapshots:"
echo ""
snapper list
echo ""

read -rp "Snapshot number to restore [q to quit]: " SNAP_NUM
[[ "$SNAP_NUM" == "q" || "$SNAP_NUM" == "Q" ]] && exit 0

if ! [[ "$SNAP_NUM" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Invalid snapshot number.${NC}"
    exit 1
fi

SNAP_SUBVOL="/.snapshots/${SNAP_NUM}/snapshot"
if [ ! -d "$SNAP_SUBVOL" ]; then
    echo -e "${RED}Snapshot ${SNAP_NUM} not found at ${SNAP_SUBVOL}.${NC}"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="@.pre-restore-${TIMESTAMP}"

echo ""
echo -e "${YELLOW}This will:${NC}"
echo -e "  1. Back up the current @ → ${BACKUP_NAME}"
echo -e "  2. Replace @ with snapshot ${SNAP_NUM}"
echo -e "  3. Reboot immediately"
echo ""
read -rp "Type 'yes' to confirm: " CONFIRM
[[ "$CONFIRM" != "yes" ]] && { echo "Aborted."; exit 0; }

BTRFS_DEV=$(findmnt -n -o SOURCE /)
MNT=$(mktemp -d)

echo ""
echo "Mounting btrfs root..."
mount -o subvolid=5 "$BTRFS_DEV" "$MNT"

cleanup() {
    mountpoint -q "$MNT" && umount "$MNT"
    rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT

echo "Backing up current @ → ${BACKUP_NAME}..."
btrfs subvolume snapshot "$MNT/@" "$MNT/${BACKUP_NAME}"

echo "Removing current @..."
if ! btrfs subvolume delete "$MNT/@"; then
    echo -e "${RED}Failed to delete @. Restore aborted — backup is at ${BACKUP_NAME}.${NC}"
    exit 1
fi

echo "Restoring snapshot ${SNAP_NUM} → @..."
btrfs subvolume snapshot "$MNT/@snapshots/${SNAP_NUM}/snapshot" "$MNT/@"

echo ""
echo -e "${GREEN}Restore complete.${NC}"
echo -e "  New @   : snapshot ${SNAP_NUM}"
echo -e "  Backup  : ${BACKUP_NAME} (delete manually once verified)"
echo ""
echo "Rebooting in 3 seconds..."
sleep 3
reboot
