#!/bin/bash
# powermenu.sh — Power menu via wofi dmenu
# Installed to ~/.local/bin/powermenu.sh by setup-hyprland-config.sh
# Bound to SUPER+SHIFT+P in bindings.conf

OPTIONS="Lock\nLogout\nSuspend\nHibernate\nReboot\nShutdown"
CHOICE=$(printf '%b' "$OPTIONS" | wofi --dmenu --prompt "Power" \
    --width 200 --height 250 --no-actions --insensitive)

case "$CHOICE" in
    Lock)      hyprlock ;;
    Logout)    hyprctl dispatch exit ;;
    Suspend)   systemctl suspend ;;
    Hibernate) systemctl hibernate ;;
    Reboot)    systemctl reboot ;;
    Shutdown)  systemctl poweroff ;;
esac
