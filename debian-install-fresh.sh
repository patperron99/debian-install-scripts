#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[+] ${NC}$1"; }
warn()  { echo -e "${YELLOW}[!] ${NC}$1"; }
error() { echo -e "${RED}[ERROR] ${NC}$1"; exit 1; }
ask()   { echo -e "${BLUE}$1${NC}"; }

get_partition_suffix() {
    local device=$1 partition_num=$2
    if echo "$device" | grep -q "nvme"; then
        echo "p${partition_num}"
    else
        echo "${partition_num}"
    fi
}

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
fi

# ── Load install.conf and .install-passwords if present ───────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/install.conf" ]; then
    log "Loading configuration from install.conf..."
    source "$SCRIPT_DIR/install.conf"
fi
if [ -f "$SCRIPT_DIR/.install-passwords" ]; then
    log "Loading passwords from .install-passwords..."
    source "$SCRIPT_DIR/.install-passwords"
fi

# Ensure password variables are always defined (even if empty)
INSTALL_LUKS_PASS="${INSTALL_LUKS_PASS:-}"
INSTALL_ROOT_PASS="${INSTALL_ROOT_PASS:-}"
INSTALL_USER_PASS="${INSTALL_USER_PASS:-}"

# ── Required tools ────────────────────────────────────────────────────────────
REQUIRED_TOOLS="debootstrap cryptsetup btrfs-progs arch-install-scripts gdisk dosfstools"
log "Installing required tools..."
apt update
apt install -y $REQUIRED_TOOLS || error "Failed to install required tools"

# ── Disk selection ────────────────────────────────────────────────────────────
mapfile -t available_disks < <(lsblk -d -n -p -o NAME | grep -E '^/dev/(sd|vd|nvme)')
if [ ${#available_disks[@]} -eq 0 ]; then
    error "No suitable disks found"
fi

if [ -n "${INSTALL_DISK:-}" ]; then
    DISK="$INSTALL_DISK"
    log "Disk from install.conf: $DISK"
else
    echo "Available disks:"
    for i in "${!available_disks[@]}"; do
        disk_info=$(lsblk -d -n -o NAME,SIZE,MODEL "${available_disks[$i]}")
        echo "[$i] $disk_info"
    done
    echo
    while true; do
        ask "Enter the disk number to use [0-$((${#available_disks[@]}-1))]: "
        read -p "" disk_num
        if [[ "$disk_num" =~ ^[0-9]+$ ]] && \
           [ "$disk_num" -ge 0 ] && [ "$disk_num" -lt "${#available_disks[@]}" ]; then
            DISK="${available_disks[$disk_num]}"
            break
        else
            warn "Invalid selection. Please try again."
        fi
    done
fi

PART1="$(get_partition_suffix "$DISK" 1)"
PART2="$(get_partition_suffix "$DISK" 2)"
PART3="$(get_partition_suffix "$DISK" 3)"

# ── Filesystem choice ─────────────────────────────────────────────────────────
if [ -n "${INSTALL_FS:-}" ]; then
    FILESYSTEM="$INSTALL_FS"
    log "Filesystem from install.conf: $FILESYSTEM"
else
    ask "Choose file system (btrfs, ext4, xfs): "
    read -p "" FILESYSTEM
fi

# ── LUKS choice ───────────────────────────────────────────────────────────────
if [ -n "${INSTALL_LUKS:-}" ]; then
    ENCRYPT="$INSTALL_LUKS"
    log "LUKS encryption from install.conf: $ENCRYPT"
else
    ask "Do you want to encrypt the root partition? (y/N): "
    read -p "" ENCRYPT
fi

if [[ "${ENCRYPT,,}" =~ ^(y|yes)$ ]]; then
    WILL_ENCRYPT=true
else
    WILL_ENCRYPT=false
fi

# ── Collect passwords upfront ─────────────────────────────────────────────────
# All interactive prompts gathered here before disk operations begin.

if $WILL_ENCRYPT && [ -z "$INSTALL_LUKS_PASS" ]; then
    while true; do
        ask "Enter LUKS passphrase: "
        read -rsp "" INSTALL_LUKS_PASS; echo
        ask "Confirm LUKS passphrase: "
        read -rsp "" _luks2; echo
        [ "$INSTALL_LUKS_PASS" = "$_luks2" ] && break
        warn "Passphrases do not match. Try again."
    done
fi

if [ -z "$INSTALL_ROOT_PASS" ]; then
    while true; do
        ask "Enter root password: "
        read -rsp "" INSTALL_ROOT_PASS; echo
        ask "Confirm root password: "
        read -rsp "" _root2; echo
        [ "$INSTALL_ROOT_PASS" = "$_root2" ] && break
        warn "Passwords do not match. Try again."
    done
fi

_uname="${INSTALL_USERNAME:-user}"
if [ -z "$INSTALL_USER_PASS" ]; then
    while true; do
        ask "Enter password for user '$_uname': "
        read -rsp "" INSTALL_USER_PASS; echo
        ask "Confirm password: "
        read -rsp "" _user2; echo
        [ "$INSTALL_USER_PASS" = "$_user2" ] && break
        warn "Passwords do not match. Try again."
    done
fi

# ── Confirmation ──────────────────────────────────────────────────────────────
warn "WARNING: This will DESTROY ALL DATA on $DISK"
log "  Filesystem : $FILESYSTEM"
log "  Encryption : $($WILL_ENCRYPT && echo "LUKS2" || echo "none")"
ask "Are you sure you want to continue? (y/N): "
read -p "" confirm
if [ "${confirm,,}" != "y" ]; then
    error "Operation cancelled by user"
fi

# ── Partitioning ──────────────────────────────────────────────────────────────
log "Creating partitions on $DISK..."
wipefs -a "$DISK" || true
sgdisk --zap-all "$DISK"
sgdisk -n 1:2048:+512M -t 1:EF00 "$DISK"
sgdisk -n 2:0:+1G    -t 2:8300 "$DISK"
sgdisk -n 3:0:0      -t 3:8309 "$DISK"

partprobe "$DISK"
sleep 2

wipefs -a "${DISK}${PART1}" || true
wipefs -a "${DISK}${PART2}" || true
wipefs -a "${DISK}${PART3}" || true

# ── LUKS setup ────────────────────────────────────────────────────────────────
if $WILL_ENCRYPT; then
    log "Setting up LUKS encryption..."
    echo -n "$INSTALL_LUKS_PASS" | \
        cryptsetup --batch-mode --type luks2 luksFormat --label Debian "${DISK}${PART3}" --key-file=-
    echo -n "$INSTALL_LUKS_PASS" | \
        cryptsetup open --key-file=- "${DISK}${PART3}" cryptroot
    ROOT_PARTITION="/dev/mapper/cryptroot"
else
    ROOT_PARTITION="${DISK}${PART3}"
fi

# ── Format partitions ─────────────────────────────────────────────────────────
log "Formatting partitions..."
mkfs.vfat "${DISK}${PART1}"
mkfs.ext4 "${DISK}${PART2}"

case $FILESYSTEM in
    btrfs) mkfs.btrfs "$ROOT_PARTITION" ;;
    ext4)  mkfs.ext4  "$ROOT_PARTITION" ;;
    xfs)   mkfs.xfs   "$ROOT_PARTITION" ;;
    *)     error "Unsupported file system: $FILESYSTEM" ;;
esac

# ── Mount ─────────────────────────────────────────────────────────────────────
if [ "$FILESYSTEM" == "btrfs" ]; then
    log "Creating btrfs subvolumes..."
    mount "$ROOT_PARTITION" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    umount /mnt
fi

case $FILESYSTEM in
    btrfs)
        mount -o noatime,compress=zstd:1,subvol=@ "$ROOT_PARTITION" /mnt
        mkdir -p /mnt/{boot,home,.snapshots}
        mount -o noatime,compress=zstd:1,subvol=@home      "$ROOT_PARTITION" /mnt/home
        mount -o noatime,compress=zstd:1,subvol=@snapshots "$ROOT_PARTITION" /mnt/.snapshots
        ;;
    *)
        mount "$ROOT_PARTITION" /mnt
        mkdir -p /mnt/{boot,home}
        ;;
esac

mount "${DISK}${PART2}" /mnt/boot/
mkdir -p /mnt/boot/efi
mount "${DISK}${PART1}" /mnt/boot/efi

# ── Debootstrap ───────────────────────────────────────────────────────────────
RELEASE="${INSTALL_RELEASE:-stable}"
log "Installing base Debian system (release: $RELEASE)..."
debootstrap --arch amd64 "$RELEASE" /mnt

log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "$DISK" > /mnt/selected_disk

# ── WiFi configuration ────────────────────────────────────────────────────────
if [ -d /etc/NetworkManager/system-connections ]; then
    if [[ "${INSTALL_COPY_WIFI,,}" =~ ^(y|yes)$ ]]; then
        COPY_WIFI="y"
    elif [[ "${INSTALL_COPY_WIFI,,}" =~ ^(n|no)$ ]]; then
        COPY_WIFI="n"
    else
        ask "Do you want to copy WiFi configuration from live system? (y/N): "
        read -p "" COPY_WIFI
    fi
    if [ "${COPY_WIFI,,}" == "y" ]; then
        log "Copying WiFi configuration..."
        mkdir -p /mnt/etc/NetworkManager/system-connections
        cp -r /etc/NetworkManager/system-connections/* \
            /mnt/etc/NetworkManager/system-connections/ 2>/dev/null \
            || warn "No WiFi connections found to copy"
        chmod 600 /mnt/etc/NetworkManager/system-connections/* 2>/dev/null || true
    fi
fi

# ── Copy repo to new system ───────────────────────────────────────────────────
log "Copying install scripts to /opt/debian-install-scripts..."
mkdir -p /mnt/opt
cp -r "$SCRIPT_DIR" /mnt/opt/debian-install-scripts
chmod -R 755 /mnt/opt/debian-install-scripts
# Ne pas copier les secrets vers le nouveau système
rm -f /mnt/opt/debian-install-scripts/.install-passwords

# ── Write secrets for chroot (shredded by chroot_setup.sh) ───────────────────
mkdir -p /mnt/tmp
{
    declare -p INSTALL_ROOT_PASS
    declare -p INSTALL_USER_PASS
    declare -p INSTALL_LUKS_PASS
} > /mnt/tmp/.install-secrets
chmod 600 /mnt/tmp/.install-secrets

# ── Chroot ────────────────────────────────────────────────────────────────────
log "Preparing chroot environment..."
cp /mnt/opt/debian-install-scripts/scripts/chroot_setup.sh /mnt/setup.sh
chmod +x /mnt/setup.sh

log "Starting chroot installation..."
arch-chroot /mnt ./setup.sh "$RELEASE"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f /mnt/setup.sh /mnt/selected_disk

# Détruire les secrets du LiveCD après le chroot
[ -f "$SCRIPT_DIR/.install-passwords" ] && shred -u "$SCRIPT_DIR/.install-passwords"

log "Installation completed! You can now reboot into your new system."
