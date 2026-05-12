#!/bin/bash
set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

if [ -n "${1:-}" ]; then
  INSTALL_USER="$1"
  INSTALL_HOME="/home/$1"
else
  INSTALL_USER="${SUDO_USER:-$USER}"
  INSTALL_HOME="$HOME"
fi

LOG_FILE="/var/log/sway-install.log"

echo -e "${GREEN}=== Sway Installation Script ===${NC}"
echo "Installs Sway and its ecosystem from Debian Testing (Forky) repositories."
echo "All packages are installed via APT — no compilation required."
echo ""

if [ -f /etc/debian_version ]; then
  DEBIAN_VERSION=$(cat /etc/debian_version)
  echo -e "${YELLOW}Detected Debian version: $DEBIAN_VERSION${NC}"
  echo ""
fi

declare -a PACKAGES=(
  # Wayland compositor
  "sway"
  "swaybg"
  "swayidle"
  "xdg-desktop-portal-wlr"
  "autotiling"

  # Status bar
  "waybar"

  # App launcher
  "wofi"

  # Notifications
  "mako-notifier"

  # Screenshot / screen recording
  "grim"
  "slurp"
  "wf-recorder"

  # Clipboard
  "wl-clipboard"
  "cliphist"

  # Audio (PipeWire only)
  "pipewire"
  "pipewire-pulse"
  "pipewire-alsa"
  "wireplumber"
  "pamixer"

  # Network
  "iwd"

  # Polkit agent (KDE — no GNOME session deps)
  "polkit-kde-agent-1"

  # Disk management
  "udiskie"
  "udisks2"

  # Fonts
  "fonts-noto"
  "fonts-noto-color-emoji"
  "fonts-font-awesome"
  "fonts-jetbrains-mono"

  # Terminal
  "alacritty"

  # Power management
  "power-profiles-daemon"

  # System utilities
  "brightnessctl"
  "playerctl"
  "bluez"
  "blueman"
  "pavucontrol"
  "kanshi"
  "swayimg"
  "imagemagick"
  "mpv"
  "imv"
  "evince"

  # Qt Wayland support
  "qtwayland5"
  "qt6-wayland"

  # Base tools
  "git"
  "curl"
  "wget"
  "unzip"
  "fzf"
  "avahi-daemon"
  "python3-pipx"

  # Flatpak (for Zen browser)
  "flatpak"
)

echo "Updating package lists..."
_APT_CMD apt update

echo ""
echo "Installing packages..."
echo ""

for pkg in "${PACKAGES[@]}"; do
  if check_package "$pkg"; then
    if install_package "$pkg"; then
      SUCCESSFUL_PACKAGES+=("$pkg")
    else
      FAILED_PACKAGES+=("$pkg")
      echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
    fi
  else
    echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
    FAILED_PACKAGES+=("$pkg")
    echo "Package not found: $pkg" | tee -a "$LOG_FILE"
  fi
done

# GNOME utilities without Recommends to prevent DE pollution
echo ""
echo "Installing GNOME utilities (no recommends)..."
for pkg in nautilus gnome-keyring gvfs-backends; do
  if check_package "$pkg"; then
    if install_package_no_recommends "$pkg"; then
      SUCCESSFUL_PACKAGES+=("$pkg")
    else
      FAILED_PACKAGES+=("$pkg")
      echo "Failed to install: $pkg" | tee -a "$LOG_FILE"
    fi
  else
    echo -e "${YELLOW}Package not found in repository: $pkg${NC}"
    FAILED_PACKAGES+=("$pkg")
    echo "Package not found: $pkg" | tee -a "$LOG_FILE"
  fi
done

echo ""
echo "Installing hyprlock from testing..."
setup_testing_sources
apt-get install -y -t testing hyprlock
echo -e "${GREEN}✓ hyprlock installed from testing${NC}"

echo ""
echo "Enabling essential services..."
systemctl enable iwd
systemctl enable bluetooth
systemctl enable avahi-daemon
systemctl enable --now power-profiles-daemon

echo ""
echo "Installing terminaltexteffects (TTE screensaver)..."
sudo -u "$INSTALL_USER" pipx install terminaltexteffects
echo -e "${GREEN}✓ terminaltexteffects installed${NC}"

echo ""
echo "Installing Zen browser via Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub app.zen_browser.zen
xdg-settings set default-web-browser app.zen_browser.zen.desktop

echo ""
echo "Setting up Sway configuration directories..."
mkdir -p "$INSTALL_HOME/.config/sway"
mkdir -p "$INSTALL_HOME/.config/waybar"
mkdir -p "$INSTALL_HOME/.config/mako"
mkdir -p "$INSTALL_HOME/.config/alacritty"
chown -R "$INSTALL_USER:$INSTALL_USER" "$INSTALL_HOME/.config"

echo ""
echo "Configuring iwd for network management..."
mkdir -p /etc/iwd
cat <<'EOF' >/etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
NameResolvingService=systemd

[Network]
EnableIPv6=true
RoutePriorityOffset=300
EOF
echo -e "${GREEN}✓ iwd configured${NC}"

echo ""
echo "Configuring TTY1 autologin for $INSTALL_USER..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $INSTALL_USER --noclear %I \$TERM
Type=simple
EOF
systemctl unmask getty@tty1.service 2>/dev/null || true
systemctl enable getty@tty1.service 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true
echo -e "${GREEN}✓ Autologin configured for $INSTALL_USER on TTY1${NC}"

print_summary

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next step:${NC}"
echo "  Run: bash scripts/setup-sway-config.sh"
echo "  Reboot — autologin on TTY1, Sway starts automatically via ~/.bash_profile"
echo ""

if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
  echo -e "${RED}Note: Some packages failed to install. Check $LOG_FILE for details.${NC}"
fi
