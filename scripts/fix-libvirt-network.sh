#!/bin/bash
# fix-libvirt-network.sh — Fix "network 'default' is not active" error in virt-manager

set -uo pipefail

source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Fixing Libvirt Default Network ===${NC}"
echo ""

# --- CHECK NETWORK STATUS ---
echo "Checking network status..."
if sudo virsh net-list | grep -q "default.*active"; then
    echo -e "${GREEN}✓ Network 'default' is already active${NC}"
    exit 0
fi

echo -e "${YELLOW}⚠ Network 'default' is not active${NC}"
echo ""

# --- DEFINE DEFAULT NETWORK IF MISSING ---
echo "Defining default network..."
if ! sudo virsh net-list --all | grep -q "default"; then
    echo "Creating default network..."
    sudo virsh net-define /dev/stdin << 'EOF'
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
EOF
    echo -e "${GREEN}✓ Default network created${NC}"
else
    echo -e "${GREEN}✓ Default network exists${NC}"
fi

echo ""

# --- START NETWORK ---
echo "Starting default network..."
if sudo virsh net-start default 2>/dev/null; then
    echo -e "${GREEN}✓ Network started${NC}"
else
    echo -e "${YELLOW}Network already running or error occurred${NC}"
fi

echo ""

# --- AUTOSTART NETWORK ---
echo "Enabling autostart for default network..."
if sudo virsh net-autostart default 2>/dev/null; then
    echo -e "${GREEN}✓ Autostart enabled${NC}"
fi

echo ""

# --- VERIFY ---
echo "Verifying network status..."
if sudo virsh net-list | grep -q "default.*active"; then
    echo -e "${GREEN}✓ Network 'default' is now active${NC}"
    echo ""
    echo "Network details:"
    sudo virsh net-info default
    echo ""
    echo -e "${GREEN}=== Fix Complete ===${NC}"
    echo ""
    echo "You can now create VMs in virt-manager without network errors."
else
    echo -e "${RED}✗ Network still not active${NC}"
    echo ""
    echo "Try these manual commands:"
    echo "  $ sudo virsh net-start default"
    echo "  $ sudo virsh net-autostart default"
    exit 1
fi
