#!/bin/bash
# setup-kvm-testing.sh — Install QEMU/KVM + Virt-Manager for testing debian-install-scripts
# Enables running debian-install-fresh.sh inside a virtual machine

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== KVM/QEMU + Virt-Manager Setup ===${NC}"
echo "Install virtualization stack for testing debian-install-scripts in VMs."
echo ""

# --- CHECK FOR KVM SUPPORT ---
echo "Checking for KVM hardware support..."
if grep -q "^flags.*\(vmx\|svm\)" /proc/cpuinfo 2>/dev/null; then
    echo -e "${GREEN}✓ CPU virtualization detected (Intel VMX or AMD SVM)${NC}"
    KVM_SUPPORTED=true
else
    echo -e "${YELLOW}⚠ CPU virtualization not detected${NC}"
    echo "  Note: KVM acceleration won't work, but QEMU emulation still available"
    KVM_SUPPORTED=false
fi

if grep -q "^flags.*kvm" /proc/cpuinfo 2>/dev/null; then
    echo -e "${GREEN}✓ KVM kernel module available${NC}"
else
    echo -e "${YELLOW}⚠ KVM kernel module not detected${NC}"
fi

echo ""

# --- INSTALL PACKAGES ---
echo "Installing KVM + Virt-Manager packages..."

declare -a KVM_PACKAGES=(
    "qemu-system-x86"
    "qemu-kvm"
    "libvirt-daemon"
    "libvirt-daemon-system"
    "libvirt-clients"
    "virt-manager"
    "virt-viewer"
    "virtinst"
    "ebtables"
    "dnsmasq"
    "bridge-utils"
    "cpu-checker"
)

_APT_CMD apt update
for pkg in "${KVM_PACKAGES[@]}"; do
    if check_package "$pkg"; then
        if install_package "$pkg" 2>/dev/null; then
            echo -e "${GREEN}✓ $pkg${NC}"
        else
            echo -e "${YELLOW}⚠ Failed to install $pkg${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Package not found: $pkg${NC}"
    fi
done

echo ""

# --- ENABLE KVM MODULE ---
echo "Loading KVM kernel modules..."
if [ "$KVM_SUPPORTED" = true ]; then
    sudo modprobe kvm
    sudo modprobe kvm_intel 2>/dev/null || sudo modprobe kvm_amd 2>/dev/null
    echo -e "${GREEN}KVM modules loaded${NC}"
else
    echo -e "${YELLOW}Skipping KVM module load (hardware not supported)${NC}"
fi

echo ""

# --- CONFIGURE PERMISSIONS ---
echo "Configuring user permissions for libvirt..."
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"
echo -e "${GREEN}Added $USER to libvirt and kvm groups${NC}"
echo -e "${YELLOW}Note: You may need to log out and back in for group changes to take effect${NC}"

echo ""

# --- ENABLE SERVICES ---
echo "Enabling libvirtd and related services..."
sudo systemctl enable libvirtd 2>/dev/null || true
sudo systemctl enable virtlogd 2>/dev/null || true
sudo systemctl start libvirtd 2>/dev/null || true
sudo systemctl start virtlogd 2>/dev/null || true
echo -e "${GREEN}Services enabled and started${NC}"

echo ""

# --- VERIFY INSTALLATION ---
echo "Verifying installation..."
if command -v virt-manager &>/dev/null; then
    echo -e "${GREEN}✓ virt-manager installed${NC}"
else
    echo -e "${YELLOW}✗ virt-manager not found${NC}"
fi

if command -v qemu-system-x86_64 &>/dev/null; then
    echo -e "${GREEN}✓ QEMU installed${NC}"
else
    echo -e "${YELLOW}✗ QEMU not found${NC}"
fi

if systemctl is-active --quiet libvirtd; then
    echo -e "${GREEN}✓ libvirtd running${NC}"
else
    echo -e "${YELLOW}✗ libvirtd not running${NC}"
fi

echo ""

# --- FIX DEFAULT NETWORK ---
echo "Fixing default network (if needed)..."
if ! sudo virsh net-list 2>/dev/null | grep -q "default.*active"; then
    echo "Defining default network..."
    cat << 'NETDEF' | sudo virsh net-define /dev/stdin >/dev/null 2>&1 || true
<network>
  <name>default</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <domain name='default'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
NETDEF
    sudo virsh net-start default 2>/dev/null || true
    sudo virsh net-autostart default 2>/dev/null || true
    echo -e "${GREEN}✓ Default network configured${NC}"
else
    echo -e "${GREEN}✓ Default network already active${NC}"
fi

echo ""

# --- DOWNLOAD ISO ---
echo "Downloading Debian Testing ISO for testing..."
ISO_DIR="$HOME/VMs"
mkdir -p "$ISO_DIR"

DEBIAN_ISO="$ISO_DIR/debian-testing.iso"
if [ -f "$DEBIAN_ISO" ]; then
    echo -e "${GREEN}Debian ISO already downloaded${NC}"
else
    echo "Downloading Debian Testing (Forky) ISO..."
    echo "  Size: ~600MB (may take a few minutes)"
    echo "  Saving to: $DEBIAN_ISO"

    # Using Debian CDN (Debian 13.4.0 = Testing/Trixie)
    ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"

    if curl -fsSL --progress-bar --connect-timeout 30 -o "$DEBIAN_ISO" "$ISO_URL" 2>/dev/null; then
        echo -e "${GREEN}✓ ISO downloaded${NC}"
    else
        echo -e "${YELLOW}Could not download ISO automatically${NC}"
        echo "  Download manually from:"
        echo "    $ISO_URL"
        echo "  Or use virt-manager to fetch during VM creation"
    fi
fi

echo ""

# --- INSTRUCTIONS ---
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "To test debian-install-scripts in a VM:"
echo ""
echo "1. Open Virt-Manager:"
echo "   $ virt-manager"
echo ""
echo "2. Create a new VM:"
echo "   • File → New Virtual Machine"
echo "   • Select: Local install media (ISO)"
echo "   • Choose ISO: $ISO_DIR/debian-testing.iso"
echo "   • Allocate resources:"
echo "     - vCPUs: 4 (or more)"
echo "     - RAM: 8GB minimum, 16GB recommended"
echo "     - Disk: 50GB minimum (for full test with snapshots)"
echo "   • Check 'Customize before install' → Add second disk (20GB) for snapper test"
echo ""
echo "3. Boot into Debian installer:"
echo "   • Choose Guided partitioning → use entire disk"
echo "   • Install base system"
echo ""
echo "4. First boot, run debian-install-fresh.sh:"
echo "   $ sudo apt install git curl"
echo "   $ git clone https://github.com/patperron99/debian-install-scripts"
echo "   $ cd debian-install-scripts"
echo "   $ sudo bash debian-install-fresh.sh"
echo ""
echo "5. Configure the installer:"
echo "   • Target disk: /dev/vda (first QEMU disk)"
echo "   • Setup LUKS, Btrfs, etc."
echo "   • Reboot when done"
echo ""
echo "6. Post-install (after reboot into new system):"
echo "   $ bash postinstall-sway.sh"
echo "   • Choose 'a' for full install, or individual steps"
echo ""
echo "Tips:"
echo "  • Use virt-manager snapshots before debian-install-fresh.sh"
echo "    (Right-click VM → Manage Snapshots → Create)"
echo "  • Allocate CPU cores from host: Ctrl+Alt+Del to access Grub"
echo "  • Enable 3D acceleration in Display settings (if supported)"
echo "  • Use SPICE protocol for better performance than VNC"
echo ""
echo "Common issues:"
echo "  • 'Permission denied' running virt-manager:"
echo "    → Log out and back in (group changes need new session)"
echo "  • VM too slow:"
echo "    → Increase vCPU count and RAM in Hardware Details"
echo "  • No network in VM:"
echo "    → Check Network interface is set to 'Virtual network (NAT)'"
echo ""

echo -e "${GREEN}Ready to test! 🚀${NC}"
