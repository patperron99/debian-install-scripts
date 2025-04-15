#!/bin/bash

RELEASE=$1

# Set up apt sources
cat > /etc/apt/sources.list << EOF
deb http://deb.debian.org/debian $RELEASE main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $RELEASE main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $RELEASE-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $RELEASE-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian $RELEASE-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian $RELEASE-updates main contrib non-free non-free-firmware
EOF

# Update and install packages
apt update
apt install -y locales
dpkg-reconfigure tzdata

# Ask for hostname
echo "Please enter the hostname for your system:"
read -r HOSTNAME

# If hostname is empty, set default
if [ -z "$HOSTNAME" ]; then
    HOSTNAME=debian-strap
    echo "No hostname provided, using default: $HOSTNAME"
else
    echo "Setting hostname to: $HOSTNAME"
fi

# Set hostname
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

# Ask for user to add
echo "Please enter the username for the new user:"
read -r USERNAME
# If username is empty, set default
if [ -z "$USERNAME" ]; then
    USERNAME=user
    echo "No username provided, using default: $USERNAME"
else
    echo "Setting username to: $USERNAME"
fi
# Create user
useradd $USERNAME -m -c "$USERNAME" -s /bin/bash
echo "Set $USERNAME password:"
passwd $USERNAME
usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,users,netdev $USERNAME

# Install and update GRUB
SELECTED_DISK=$(cat /selected_disk)
grub-install "$SELECTED_DISK"
update-grub

echo "Installation completed successfully!"
