#!/bin/bash

set -e

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored messages
log() {
    echo -e "${GREEN}[+] ${NC}$1"
}

warn() {
    echo -e "${YELLOW}[!] ${NC}$1"
}

error() {
    echo -e "${RED}[ERROR] ${NC}$1"
    exit 1
}

# Function to get partition number for a device
get_partition_suffix() {
    local device=$1
    local partition_num=$2
    
    if echo "$device" | grep -q "nvme"; then
        echo "p${partition_num}"
    else
        echo "${partition_num}"
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root"
fi

# Check for required tools
REQUIRED_TOOLS="debootstrap cryptsetup btrfs-progs arch-install-scripts gdisk dosfstools"
log "Installing required tools..."
apt update
apt install -y $REQUIRED_TOOLS || error "Failed to install required tools"

# Disk selection
mapfile -t available_disks < <(lsblk -d -n -p -o NAME | grep -E '^/dev/(sd|vd|nvme)')
if [ ${#available_disks[@]} -eq 0 ]; then
    error "No suitable disks found"
fi

echo "Available disks:"
for i in "${!available_disks[@]}"; do
    disk_info=$(lsblk -d -n -o NAME,SIZE,MODEL "${available_disks[$i]}")
    echo "[$i] $disk_info"
done
echo

while true; do
    read -p "Enter the disk number to use [0-$((${#available_disks[@]}-1))]: " disk_num
    if [[ "$disk_num" =~ ^[0-9]+$ ]] && [ "$disk_num" -ge 0 ] && [ "$disk_num" -lt "${#available_disks[@]}" ]; then
        DISK="${available_disks[$disk_num]}"
        break
    else
        warn "Invalid selection. Please try again."
    fi
done

# Get partition suffixes based on device type
PART1="$(get_partition_suffix "$DISK" 1)"
PART2="$(get_partition_suffix "$DISK" 2)"
PART3="$(get_partition_suffix "$DISK" 3)"

# Confirmation
warn "WARNING: This will DESTROY ALL DATA on $DISK"
read -p "Are you sure you want to continue? (y/N): " confirm
if [ "${confirm,,}" != "y" ]; then
    error "Operation cancelled by user"
fi

# Partition the disk
log "Creating partitions on $DISK..."
sgdisk --zap-all "$DISK"
sgdisk -n 1:2048:+512M -t 1:EF00 "$DISK"  # EFI
sgdisk -n 2:0:+1G -t 2:8300 "$DISK"       # Boot
sgdisk -n 3:0:0 -t 3:8309 "$DISK"         # Root

# Setup LUKS
log "Setting up LUKS encryption..."
cryptsetup -y -v --type luks2 luksFormat --label Debian "${DISK}${PART3}"
cryptsetup open "${DISK}${PART3}" cryptroot

# Format partitions
log "Formatting partitions..."
mkfs.vfat "${DISK}${PART1}"
mkfs.ext4 "${DISK}${PART2}"
mkfs.btrfs /dev/mapper/cryptroot

# Create and mount btrfs subvolumes
log "Creating and mounting btrfs subvolumes..."
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Mount all partitions
mount -o noatime,compress=zstd:1,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{boot,home,.snapshots}
mount -o noatime,compress=zstd:1,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o noatime,compress=zstd:1,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount "${DISK}${PART2}" /mnt/boot/
mkdir -p /mnt/boot/efi
mount "${DISK}${PART1}" /mnt/boot/efi

# Install base system
log "Installing base Debian system..."
debootstrap --arch amd64 trixie /mnt

# Generate fstab
log "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Store the selected disk for use in chroot
echo "$DISK" > /mnt/selected_disk

# Prepare chroot environment
log "Preparing chroot environment..."
cat > /mnt/setup.sh << 'EOF'
#!/bin/bash

# Set up apt sources
cat > /etc/apt/sources.list << 'SOURCES'
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
SOURCES

# Update and install packages
apt update
apt install -y locales
dpkg-reconfigure tzdata
dpkg-reconfigure locales

# Set hostname
HOSTNAME=debian-strap
echo $HOSTNAME > /etc/hostname
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Install essential packages
apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree \
    sudo vim bash-completion grub-efi-amd64 network-manager btrfs-progs \
    cryptsetup openssh-server git plymouth plymouth-themes wget

# Configure cryptsetup and GRUB
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "GRUB_BACKGROUND=" >> /etc/default/grub
CRYPT_UUID=$(blkid -s UUID -o value $(findfs LABEL=Debian))
echo "cryptroot UUID=$CRYPT_UUID none luks,discard" >> /etc/crypttab
apt install -y cryptsetup-initramfs

# Configure tmpfs for /tmp
echo "tmpfs /tmp tmpfs rw,nosuid,nodev 0 0" >> /etc/fstab

# Set root password
echo "Set root password:"
passwd

# Create user
useradd sysadmin -m -c "sysadmin" -s /bin/bash
echo "Set sysadmin password:"
passwd sysadmin
usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,users,netdev sysadmin

# Install and update GRUB
SELECTED_DISK=$(cat /selected_disk)
grub-install "$SELECTED_DISK"
update-grub

echo "Installation completed successfully!"
EOF

chmod +x /mnt/setup.sh

# Chroot and run setup
log "Starting chroot installation..."
arch-chroot /mnt ./setup.sh

# Cleanup
rm /mnt/setup.sh /mnt/selected_disk
log "Installation completed! You can now reboot into your new system."
