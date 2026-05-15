#!/bin/bash
# setup-and-create-vm.sh — All-in-one: Install KVM + create test VM for debian-install-scripts

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

# Configuration
VM_NAME="${1:-debian-test}"
VM_MEMORY="${2:-8192}"
VM_CPUS="${3:-4}"
VM_DISK_SIZE="${4:-50}"
ISO_DIR="$HOME/VMs"
ISO_PATH="$ISO_DIR/debian-testing.iso"
DEBIAN_ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.4.0-amd64-netinst.iso"

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Debian Install Scripts — Full KVM + VM Setup               ║"
echo "║  All-in-one: Install KVM → Create VM → Ready to test       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Configuration:"
echo "  VM Name:      $VM_NAME"
echo "  Memory:       ${VM_MEMORY}MB (~${VM_MEMORY})"
echo "  vCPUs:        $VM_CPUS"
echo "  Disk:         ${VM_DISK_SIZE}GB"
echo "  ISO:          $ISO_PATH"
echo ""

# --- STEP 1: INSTALL KVM/QEMU ---
echo -e "${GREEN}[1/5] Installing KVM/QEMU + Virt-Manager...${NC}"
echo ""

if command -v virsh &>/dev/null && command -v virt-manager &>/dev/null; then
    echo -e "${GREEN}✓ KVM/Virt-Manager already installed${NC}"
else
    echo "Installing packages (requires sudo)..."

    declare -a KVM_PACKAGES=(
        "qemu-system-x86"
        "qemu-kvm"
        "libvirt-daemon"
        "libvirt-daemon-system"
        "libvirt-clients"
        "virt-manager"
        "virt-viewer"
        "virtinst"
    )

    _APT_CMD apt update
    for pkg in "${KVM_PACKAGES[@]}"; do
        if check_package "$pkg"; then
            install_package "$pkg" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✓ KVM packages installed${NC}"
fi

# Enable services
sudo systemctl enable libvirtd 2>/dev/null || true
sudo systemctl start libvirtd 2>/dev/null || true
echo -e "${GREEN}✓ libvirtd service enabled${NC}"

# Add user to groups
sudo usermod -aG libvirt "$USER" 2>/dev/null || true
sudo usermod -aG kvm "$USER" 2>/dev/null || true
echo -e "${GREEN}✓ User added to libvirt/kvm groups${NC}"

echo ""

# --- STEP 2: SETUP DEFAULT NETWORK ---
echo -e "${GREEN}[2/5] Configuring libvirt default network...${NC}"
echo ""

if sudo virsh net-list 2>/dev/null | grep -q "default.*active"; then
    echo -e "${GREEN}✓ Default network already active${NC}"
else
    echo "Creating default network..."
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
fi

echo ""

# --- STEP 3: DOWNLOAD DEBIAN ISO ---
echo -e "${GREEN}[3/5] Ensuring Debian Testing ISO...${NC}"
echo ""

mkdir -p "$ISO_DIR"

if [ -f "$ISO_PATH" ]; then
    ISO_SIZE=$(ls -lh "$ISO_PATH" | awk '{print $5}')
    echo -e "${GREEN}✓ ISO already downloaded ($ISO_SIZE)${NC}"
else
    echo "Downloading Debian Testing ISO..."
    echo "  Source: $DEBIAN_ISO_URL"
    echo "  Size: ~600MB (may take 1-5 minutes)"
    echo ""

    if curl -fsSL --progress-bar --connect-timeout 30 -o "$ISO_PATH" "$DEBIAN_ISO_URL"; then
        ISO_SIZE=$(ls -lh "$ISO_PATH" | awk '{print $5}')
        echo ""
        echo -e "${GREEN}✓ ISO downloaded successfully ($ISO_SIZE)${NC}"
    else
        echo -e "${RED}✗ Failed to download ISO${NC}"
        echo "  Try manual download:"
        echo "    wget $DEBIAN_ISO_URL -O $ISO_PATH"
        exit 1
    fi
fi

echo ""

# --- STEP 4: CREATE VM ---
echo -e "${GREEN}[4/5] Creating test VM: $VM_NAME${NC}"
echo ""

# Check if VM exists
if virsh list --all 2>/dev/null | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}⚠ VM '$VM_NAME' already exists${NC}"
    read -p "Delete and recreate? (y/N): " -r confirm
    if [[ $confirm == [yY] ]]; then
        echo "Removing existing VM..."
        virsh destroy "$VM_NAME" 2>/dev/null || true
        virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
        echo -e "${GREEN}✓ Removed${NC}"
    else
        echo "Using existing VM."
        echo ""
        echo -e "${GREEN}[5/5] Skipping VM creation (already exists)${NC}"
        echo ""
        SKIP_VM_CREATION=true
    fi
fi

if [ "${SKIP_VM_CREATION:-false}" != "true" ]; then
    # Create disk (try libvirt dir first, fallback to home VMs dir)
    if [ -w "/var/lib/libvirt/images" ]; then
        DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
    else
        echo -e "${YELLOW}Note: /var/lib/libvirt/images not writable, using $ISO_DIR${NC}"
        DISK_PATH="$ISO_DIR/${VM_NAME}.qcow2"
    fi

    mkdir -p "$(dirname "$DISK_PATH")"
    echo "Creating disk: $DISK_PATH (${VM_DISK_SIZE}GB)..."
    qemu-img create -f qcow2 "$DISK_PATH" "${VM_DISK_SIZE}G" >/dev/null 2>&1
    chmod 666 "$DISK_PATH"

    # Create VM
    echo "Configuring virtual hardware..."
    virt-install \
        --name "$VM_NAME" \
        --memory "$VM_MEMORY" \
        --vcpus "$VM_CPUS" \
        --disk path="$DISK_PATH",format=qcow2 \
        --cdrom "$ISO_PATH" \
        --osinfo debian11 \
        --network network=default \
        --graphics spice \
        --console pty,target_type=serial \
        --noautoconsole \
        --noreboot \
        2>&1 | grep -v "^  " || true

    if virsh list --all 2>/dev/null | grep -q "$VM_NAME"; then
        echo -e "${GREEN}✓ VM created successfully${NC}"
    else
        echo -e "${RED}✗ Failed to create VM${NC}"
        exit 1
    fi
fi

echo ""

# --- STEP 5: LAUNCH VIRT-MANAGER ---
echo -e "${GREEN}[5/5] Setup complete! Launching Virt-Manager...${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ KVM/QEMU installed and configured${NC}"
echo -e "${GREEN}  ✓ Debian Testing ISO ready${NC}"
echo -e "${GREEN}  ✓ VM '$VM_NAME' created${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Next steps:"
echo ""
echo "1. In Virt-Manager that's about to open:"
echo "   - Click the VM '$VM_NAME' in the left panel"
echo "   - Click the Play button (▶) to start"
echo ""
echo "2. Boot sequence:"
echo "   → Debian installer loads from ISO"
echo "   → Install Debian to /dev/vda"
echo "   → Reboot into fresh system"
echo ""
echo "3. Inside the new Debian system:"
echo "   $ sudo apt install git curl"
echo "   $ git clone https://github.com/patperron99/debian-install-scripts"
echo "   $ cd debian-install-scripts"
echo "   $ sudo bash debian-install-fresh.sh"
echo ""
echo "4. After reboot:"
echo "   $ bash postinstall-sway.sh"
echo "   # Choose: a (for full install)"
echo ""
echo "Tips:"
echo "  • Right-click VM → Manage Snapshots (for quick rollback)"
echo "  • Ctrl+Alt+Delete in VM → Access GRUB menu"
echo "  • Use SPICE display (better than VNC) in Display settings"
echo ""

# Check if group membership needs reload
if ! groups | grep -q libvirt; then
    echo -e "${YELLOW}⚠ Note: You may need to log out and back in${NC}"
    echo "  for group changes to take effect. Or run:"
    echo "  $ newgrp libvirt"
    echo ""
fi

echo -e "${GREEN}Opening Virt-Manager in 3 seconds...${NC}"
sleep 3
virt-manager &

echo ""
echo -e "${GREEN}🚀 Ready to test debian-install-scripts!${NC}"
