#!/bin/bash
# fix-apt-hooks.sh — Patch APT hooks pour APT 3.0 (Debian 13)

set -e

cat > /usr/local/bin/waybar-signal-updates << 'EOF'
#!/bin/sh
pkill -RTMIN+8 waybar >/dev/null 2>&1
exit 0
EOF
chmod +x /usr/local/bin/waybar-signal-updates
echo "Fixed: /usr/local/bin/waybar-signal-updates"

cat > /usr/local/bin/snapper-apt-pre << 'EOF'
#!/bin/sh
[ -x /usr/bin/snapper ] || exit 0
NUM=$(snapper -c root create --type pre --cleanup-algorithm number --print-number --description "apt" 2>/dev/null) || true
echo "$NUM" > /run/snapper-apt-pre-number
exit 0
EOF
chmod +x /usr/local/bin/snapper-apt-pre
echo "Fixed: /usr/local/bin/snapper-apt-pre"

cat > /usr/local/bin/snapper-apt-post << 'EOF'
#!/bin/sh
[ -x /usr/bin/snapper ] || exit 0
PRE=$(cat /run/snapper-apt-pre-number 2>/dev/null) || exit 0
snapper -c root create --type post --cleanup-algorithm number --pre-number "$PRE" --description "apt" || true
rm -f /run/snapper-apt-pre-number
update-grub 2>/dev/null || true
exit 0
EOF
chmod +x /usr/local/bin/snapper-apt-post
echo "Fixed: /usr/local/bin/snapper-apt-post"

# APT 3.0 : utiliser APT::Update::Post-Invoke (pas Post-Invoke-Success)
# et envelopper dans sh -c pour garantir exit 0
cat > /etc/apt/apt.conf.d/81waybar-updates << 'EOF'
APT::Update::Post-Invoke { "sh -c '/usr/local/bin/waybar-signal-updates || true'"; };
DPkg::Post-Invoke { "sh -c '/usr/local/bin/waybar-signal-updates || true'"; };
EOF
echo "Fixed: /etc/apt/apt.conf.d/81waybar-updates"

echo ""
echo "Done. Test avec: sudo apt update"
