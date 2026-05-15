# Testing debian-install-scripts with KVM/QEMU

Guide for testing the complete Debian Sway installation suite in a virtual machine.

---

## Prerequisites

- **Host machine:** Debian Stable/Testing with Intel/AMD virtualization support
- **CPU:** 8+ cores (4+ for VM)
- **RAM:** 16GB+ (8GB for VM + 8GB for host)
- **Disk:** 100GB free (50GB for test VM, 50GB for snapshots/testing)

---

## Step 1: Install Virtualization Stack

```bash
cd ~/debian-install-scripts
bash scripts/setup-kvm-testing.sh
```

This installs:
- QEMU/KVM (virtualization engines)
- libvirt (daemon + management library)
- Virt-Manager (GUI tool)
- Virt-Viewer (VM display)
- Virtinst (VM creation utilities)

**After installation:**
- Log out and back in (for group membership to take effect)
- Or: `newgrp libvirt` to activate in current session

---

## Step 2: Create Test VM

### Option A: Graphical (Virt-Manager)

```bash
virt-manager
```

1. **File** → **New Virtual Machine**
2. **Select installation media**
   - Choose "Local install media (ISO)"
   - Browse to: `~/VMs/debian-testing.iso`
   - If not downloaded yet, select "Download an OS" → search "Debian 12"

3. **Configure VM resources**
   - vCPU: 4–8 cores
   - RAM: 8–16 GB
   - Storage: 50 GB (ext4 or btrfs)
   - Network: "Virtual network (NAT)" for internet access

4. **Before starting:**
   - ✅ Check "Customize before install"
   - Add second disk (20 GB) if testing snapshots
   - Set Display to SPICE (better performance than VNC)
   - Enable 3D acceleration (if GPU passthrough desired)

5. **Start VM** and boot into Debian installer

---

### Option B: Command-line (virsh)

```bash
# Create VM from Debian ISO
virt-install \
  --name debian-test \
  --ram 8192 \
  --vcpus 4 \
  --disk path=/var/lib/libvirt/images/debian-test.qcow2,size=50 \
  --cdrom ~/VMs/debian-testing.iso \
  --osinfo debian11 \
  --network network=default \
  --graphics spice \
  --console pty,target_type=serial
```

---

## Step 3: Install Debian Base System

In the Debian installer:

1. **Partitioning:** Choose "Guided - use entire disk"
2. **Filesystem:** ext4 (simpler for first test) or btrfs (for snapshot testing)
3. **Software selection:** Deselect desktop, select "SSH server" only
4. **Boot into the installed system**

---

## Step 4: Run debian-install-fresh.sh

Inside the VM:

```bash
sudo apt update
sudo apt install git curl

git clone https://github.com/patperron99/debian-install-scripts
cd debian-install-scripts

# Run the fresh install script
sudo bash debian-install-fresh.sh
```

**During debian-install-fresh.sh:**
- **Target disk:** Use `/dev/vda` (main QEMU disk)
- **LUKS password:** Use a test password (e.g., `test123`)
- **Btrfs layout:** Creates subvolumes `@`, `@home`, `@snapshots`
- **GRUB config:** Auto-configured
- **Reboot when prompted**

---

## Step 5: Run postinstall-sway.sh

After reboot (into the freshly installed system):

```bash
cd ~/debian-install-scripts

# Full automated install
bash postinstall-sway.sh
# Then choose: a

# Or step-by-step for testing specific features
bash postinstall-sway.sh
# Then choose: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
```

---

## Step 6: Validate Installation

Test the installed Sway environment:

```bash
# SSH into the VM (from host)
ssh user@<vm-ip>

# On VM, verify Sway is running
systemctl --user status sway 2>/dev/null || echo "Sway not started (expected, need TTY)"

# Run diagnostic
bash scripts/verify-install.sh

# Check that services are enabled
systemctl status apt-refresh.timer
systemctl --user status check-updates.timer
systemctl status snapper
```

---

## Testing Scenarios

### Scenario 1: Basic Installation (30 min)

Test the core Sway install without optional features:

```bash
bash postinstall-sway.sh
# Choose: 1, 2, 3, 10 only
```

**Validates:**
- Package installation
- Config deployment
- System verification

---

### Scenario 2: Full Install (2-3 hours)

Test complete setup including snapshots, updates, multi-monitor:

```bash
bash postinstall-sway.sh
# Choose: a
```

**Validates:**
- All features working
- No dependency issues
- Final state consistency

---

### Scenario 3: Snapshot Testing (45 min)

Specifically test Btrfs snapshots and GRUB recovery:

1. **Before testing snapshots:**
   ```bash
   # Create a test file
   echo "test data" > /tmp/test-before.txt
   ```

2. **Create snapshot:**
   ```bash
   bash scripts/setup-snapshots.sh
   ```

3. **Test snapshot creation:**
   ```bash
   sudo snapper -c root create --description "test-snapshot"
   sudo snapper -c root list
   ```

4. **Modify system:**
   ```bash
   # Remove or modify something
   rm /tmp/test-before.txt
   ```

5. **Boot from snapshot:**
   ```bash
   # Reboot, then select snapshot in GRUB menu
   # Verify restored state
   ```

---

### Scenario 4: Multi-Monitor (15 min)

Test Sway with multi-monitor setup:

1. **In virt-manager:**
   - Right-click VM → Details
   - Display → Add another display (second monitor)

2. **In VM:**
   ```bash
   bash scripts/setup-multimonitor.sh
   ```

3. **Validate:**
   ```bash
   swaymsg -t get_outputs
   ```

---

## VM Snapshots (for fast testing)

Use virt-manager snapshots to quickly revert failed tests:

```bash
# In virt-manager:
# Right-click VM → Manage Snapshots

# Create snapshot before risky operations:
# → Create Snapshot → "Before APT" / "Before Snapshots" etc.

# Revert to snapshot:
# Right-click snapshot → Revert to Snapshot
```

This allows rapid iteration without reinstalling.

---

## Performance Tuning

If VM is slow:

### Allocate More Resources
```bash
virt-manager
# Right-click VM → Details
# CPUs: increase from 4 to 6–8
# Memory: increase from 8GB to 16GB
```

### Enable Nested Virtualization (for extra test VM)
```bash
# Check if supported:
kvm-ok

# In VM, check nested KVM:
cat /sys/module/kvm_intel/parameters/nested  # Should be 1 or Y
```

### Use SPICE Display
```bash
virt-manager → Display → Change to SPICE (not VNC)
# Better performance for Wayland
```

---

## Troubleshooting

### "network 'default' is not active" error
```bash
# Check network status
sudo virsh net-list --all

# Create and start default network
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

# Start and autostart
sudo virsh net-start default
sudo virsh net-autostart default

# Verify
sudo virsh net-list
```

Then restart virt-manager.

---

### "Permission denied" running virt-manager
```bash
# Log out and back in, then:
virt-manager

# Or activate group in current session:
newgrp libvirt
```

### VM has no network
```bash
# Check network interface:
virt-manager → Details → NIC → Network source = "Virtual network (NAT)"

# Restart network inside VM:
sudo systemctl restart networking
```

### KVM not available (hardware not supported)
```bash
# Will fall back to QEMU emulation (much slower)
# To test anyway:
virt-install --name ... --connect qemu:///system  # Use system instead of system:qemu
```

### Disk space issues
```bash
# Check VM disk usage:
df -h

# Inside VM:
sudo du -sh /var/lib/libvirt/

# Or allocate larger disk:
virt-manager → Details → Storage → Add disk (20GB for snapshots)
```

---

## Cleanup

After testing:

### Stop VM
```bash
virt-manager
# Right-click VM → Shut Down
```

### Delete VM (if no longer needed)
```bash
virt-manager
# Right-click VM → Delete
# ☑ Delete associated storage
```

### Free up disk
```bash
# Disk images are stored in:
ls -lh /var/lib/libvirt/images/

# Delete old test VMs:
sudo rm /var/lib/libvirt/images/debian-test.qcow2
```

---

## CI/CD Integration (Future)

For automated testing in CI:

```bash
#!/bin/bash
# Run headless (no display)
virt-install \
  --connect qemu:///system \
  --name ci-test \
  --memory 8192 \
  --vcpus 4 \
  --disk pool=default,size=50 \
  --cdrom debian-testing.iso \
  --nographics \
  --wait 120

# Run tests inside
virt-virsh sendkey ci-test Return
virt-virsh console ci-test
```

---

## See Also

- [Sway Documentation](https://swaywm.org/)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [libvirt Documentation](https://libvirt.org/docs.html)
- [Virt-Manager](https://virt-manager.org/)
