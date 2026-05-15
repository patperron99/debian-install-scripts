#!/bin/bash
# create-test-vm.sh — Automatically create a test VM for debian-install-scripts

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

# Default values
VM_NAME="${1:-debian-test}"
VM_MEMORY="${2:-8192}"
VM_CPUS="${3:-4}"
VM_DISK_SIZE="${4:-50}"
ISO_PATH="${5:-$HOME/VMs/debian-testing.iso}"

echo -e "${GREEN}=== Creating Test VM ===${NC}"
echo ""
echo "Configuration:"
echo "  VM Name:     $VM_NAME"
echo "  Memory:      ${VM_MEMORY}MB"
echo "  vCPUs:       $VM_CPUS"
echo "  Disk:        ${VM_DISK_SIZE}GB"
echo "  ISO:         $ISO_PATH"
echo ""

# --- VALIDATE PREREQUISITES ---
echo "Validating prerequisites..."

# Check KVM
if ! virsh version &>/dev/null; then
    echo -e "${RED}✗ libvirt not accessible${NC}"
    echo "  Run: bash scripts/setup-kvm-testing.sh"
    exit 1
fi
echo -e "${GREEN}✓ libvirt accessible${NC}"

# Check default network
if ! sudo virsh net-list | grep -q "default.*active"; then
    echo -e "${RED}✗ Default network not active${NC}"
    echo "  Run: sudo virsh net-start default"
    exit 1
fi
echo -e "${GREEN}✓ Default network active${NC}"

# Check ISO
if [ ! -f "$ISO_PATH" ]; then
    echo -e "${RED}✗ ISO not found: $ISO_PATH${NC}"
    echo "  Expected: $ISO_PATH"
    exit 1
fi
echo -e "${GREEN}✓ ISO found: $ISO_PATH${NC}"

echo ""

# --- CHECK IF VM EXISTS ---
if virsh list --all | grep -q "$VM_NAME"; then
    echo -e "${YELLOW}⚠ VM '$VM_NAME' already exists${NC}"
    read -p "Delete and recreate? (y/N): " -r confirm
    if [[ $confirm == [yY] ]]; then
        echo "Removing existing VM..."
        virsh destroy "$VM_NAME" 2>/dev/null || true
        virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
        echo -e "${GREEN}✓ Removed${NC}"
    else
        echo "Aborted."
        exit 0
    fi
    echo ""
fi

# --- CREATE VM ---
echo "Creating VM..."

# Create disk
DISK_PATH="/var/lib/libvirt/images/${VM_NAME}.qcow2"
echo "  Creating disk: $DISK_PATH (${VM_DISK_SIZE}GB)"
sudo qemu-img create -f qcow2 "$DISK_PATH" "${VM_DISK_SIZE}G" >/dev/null
sudo chmod 666 "$DISK_PATH"

# Create VM with virt-install
echo "  Configuring virtual hardware..."
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

if virsh list --all | grep -q "$VM_NAME"; then
    echo -e "${GREEN}✓ VM created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create VM${NC}"
    exit 1
fi

echo ""

# --- CREATE SNAPSHOT BEFORE FIRST BOOT ---
echo "Creating snapshot (for quick rollback)..."
virsh snapshot-create-as "$VM_NAME" "pre-install" \
    "Before Debian installation" \
    --disk-only 2>/dev/null && \
    echo -e "${GREEN}✓ Snapshot created${NC}" || \
    echo -e "${YELLOW}⚠ Snapshot creation skipped (offline VM)${NC}"

echo ""

# --- DISPLAY INFO ---
echo -e "${GREEN}=== VM Ready ===${NC}"
echo ""
echo "To start the VM:"
echo "  $ virt-manager"
echo "  or"
echo "  $ virsh start $VM_NAME"
echo ""
echo "VM Information:"
echo "  Disk:   $DISK_PATH"
echo "  Memory: ${VM_MEMORY}MB"
echo "  vCPUs:  $VM_CPUS"
echo ""
echo "Boot sequence:"
echo "  1. VM will boot from ISO (Debian installer)"
echo "  2. Install Debian to /dev/vda"
echo "  3. Reboot into installed system"
echo "  4. Run: sudo bash debian-install-fresh.sh"
echo ""
echo "Tips:"
echo "  • Right-click VM in virt-manager for snapshots"
echo "  • Ctrl+Alt+Delete to access GRUB menu"
echo "  • Use SPICE display for better performance"
echo ""
echo -e "${GREEN}Ready to test! 🚀${NC}"
