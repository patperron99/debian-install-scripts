#!/bin/bash

RELEASE=$1

# Load install.conf and injected secrets (written by debian-install-fresh.sh)
[ -f /opt/debian-install-scripts/install.conf ] && source /opt/debian-install-scripts/install.conf
[ -f /tmp/.install-secrets ]                    && source /tmp/.install-secrets

# Defaults for any variable not set via install.conf
INSTALL_LOCALE="${INSTALL_LOCALE:-fr_FR.UTF-8}"
INSTALL_TIMEZONE="${INSTALL_TIMEZONE:-America/Montreal}"
INSTALL_HOSTNAME="${INSTALL_HOSTNAME:-debian-strap}"
INSTALL_USERNAME="${INSTALL_USERNAME:-user}"

# ── APT sources ───────────────────────────────────────────────────────────────
cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian $RELEASE main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $RELEASE main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $RELEASE-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $RELEASE-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $RELEASE-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $RELEASE-updates main contrib non-free non-free-firmware
EOF

apt update
apt install -y locales tzdata

# ── Locale ────────────────────────────────────────────────────────────────────
echo "Configuring locale: $INSTALL_LOCALE"
echo "$INSTALL_LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$INSTALL_LOCALE" > /etc/default/locale

# ── Timezone ──────────────────────────────────────────────────────────────────
echo "Configuring timezone: $INSTALL_TIMEZONE"
ln -sf "/usr/share/zoneinfo/$INSTALL_TIMEZONE" /etc/localtime
hwclock --systohc

# ── Hostname ──────────────────────────────────────────────────────────────────
echo "Setting hostname: $INSTALL_HOSTNAME"
echo "$INSTALL_HOSTNAME" > /etc/hostname
echo "127.0.1.1 $INSTALL_HOSTNAME.localdomain $INSTALL_HOSTNAME" >> /etc/hosts

# ── Essential packages ────────────────────────────────────────────────────────
apt install -y linux-image-amd64 linux-headers-amd64 firmware-linux firmware-linux-nonfree \
    firmware-iwlwifi firmware-realtek \
    sudo vim bash-completion grub-efi-amd64 network-manager btrfs-progs \
    cryptsetup openssh-server git plymouth plymouth-themes wget curl \
    wpasupplicant iw rfkill pciutils usbutils build-essential dkms

# ── LUKS / crypttab ───────────────────────────────────────────────────────────
if findfs LABEL=Debian 2>/dev/null | xargs -I{} cryptsetup isLuks {} 2>/dev/null; then
    echo "Configuring encrypted system..."
    apt install -y cryptsetup-initramfs
    CRYPT_UUID=$(blkid -s UUID -o value "$(findfs LABEL=Debian)")
    echo "cryptroot UUID=$CRYPT_UUID none luks,discard" >> /etc/crypttab
    echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
fi

echo "GRUB_BACKGROUND=" >> /etc/default/grub
echo "tmpfs /tmp tmpfs rw,nosuid,nodev 0 0" >> /etc/fstab

# ── Root password ─────────────────────────────────────────────────────────────
if [ -n "${INSTALL_ROOT_PASS:-}" ]; then
    echo "root:$INSTALL_ROOT_PASS" | chpasswd
    echo "Root password set."
else
    echo "Set root password:"
    passwd
fi

# ── User creation ─────────────────────────────────────────────────────────────
echo "Creating user: $INSTALL_USERNAME"
useradd "$INSTALL_USERNAME" -m -c "$INSTALL_USERNAME" -s /bin/bash
if [ -n "${INSTALL_USER_PASS:-}" ]; then
    echo "$INSTALL_USERNAME:$INSTALL_USER_PASS" | chpasswd
    echo "User password set."
else
    echo "Set $INSTALL_USERNAME password:"
    passwd "$INSTALL_USERNAME"
fi
usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,users,netdev "$INSTALL_USERNAME"

# ── Sway postinstall ──────────────────────────────────────────────────────────
REPO_DIR="/opt/debian-install-scripts"
if [ -d "$REPO_DIR" ]; then
    bash "$REPO_DIR/scripts/chroot-postinstall.sh" "$INSTALL_USERNAME"
else
    echo "[WARN] $REPO_DIR not found — skipping Sway postinstall."
    echo "       Run postinstall-sway.sh manually after reboot."
fi

# ── Shred secrets ─────────────────────────────────────────────────────────────
[ -f /tmp/.install-secrets ] && shred -u /tmp/.install-secrets

# ── Initramfs + GRUB ──────────────────────────────────────────────────────────
echo "Updating initramfs..."
update-initramfs -u -k all

SELECTED_DISK=$(cat /selected_disk)
echo "Installing GRUB to $SELECTED_DISK..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Debian "$SELECTED_DISK"
update-grub

echo "Installation completed successfully!"
