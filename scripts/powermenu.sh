#!/bin/bash
# powermenu.sh — Power menu via wofi dmenu
# Installed to ~/.local/bin/powermenu.sh by setup-sway-config.sh
# Bound to SUPER+SHIFT+P in sway config

OPTIONS="Screensaver\nLock\nLogout\nSuspend\nHibernate\nReboot\nShutdown"
CHOICE=$(printf '%b' "$OPTIONS" | wofi --dmenu --prompt "Power" \
    --width 200 --height 290 --no-actions --insensitive)

case "$CHOICE" in
    Screensaver) bash ~/.local/bin/screensaver-launch.sh ;;
    Lock)        hyprlock ;;
    Logout)      swaymsg exit ;;
    Suspend)     systemctl suspend ;;
    Hibernate)   systemctl hibernate ;;
    Reboot)      systemctl reboot ;;
    Shutdown)    systemctl poweroff ;;
esac
