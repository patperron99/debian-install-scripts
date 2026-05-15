#!/bin/bash
# fix-libvirt-permissions.sh — Fix libvirt disk storage permissions

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Fixing Libvirt Storage Permissions ===${NC}"
echo ""

# --- FIX STORAGE POOL DIRECTORY ---
echo "Fixing /var/lib/libvirt/images directory..."

STORAGE_DIR="/var/lib/libvirt/images"

# Create directory if it doesn't exist
sudo mkdir -p "$STORAGE_DIR"

# Fix ownership
sudo chown -R libvirt-qemu:libvirt "$STORAGE_DIR"

# Fix permissions (rwx for group)
sudo chmod -R 775 "$STORAGE_DIR"

echo -e "${GREEN}✓ Directory permissions fixed${NC}"
echo "  Owner: libvirt-qemu:libvirt"
echo "  Mode: 775"
echo ""

# --- VERIFY ---
echo "Verifying..."
ls -ld "$STORAGE_DIR"
echo ""

# --- RESTART LIBVIRTD ---
echo "Restarting libvirtd service..."
sudo systemctl restart libvirtd 2>/dev/null

echo -e "${GREEN}✓ Service restarted${NC}"
echo ""

echo -e "${GREEN}=== Fix Complete ===${NC}"
echo ""
echo "You can now create VMs without permission errors."
echo ""
echo "Next: bash scripts/setup-and-create-vm.sh"
