#!/bin/bash
# wifi_menu.sh — Wofi WiFi manager using nmcli

WIFI_DEV=$(nmcli -t -f device,type device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')

if [ -z "$WIFI_DEV" ]; then
    notify-send "WiFi" "No WiFi device found"
    exit 1
fi

# Rescan
nmcli device wifi rescan ifname "$WIFI_DEV" 2>/dev/null

# Build menu: active first (marked with *), then others sorted by signal
ACTIVE=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | \
    awk -F: '$1=="yes" && $2!="" {printf "* %s [%s%%]\n", $2, $3; exit}')

OTHERS=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | \
    awk -F: '$1!="yes" && $2!="" {printf "%s [%s%%]\n", $2, $3}' | \
    sort -t'[' -k2 -rn | uniq | head -20)

MENU=$(printf '%s\n' ${ACTIVE:+"$ACTIVE"} "$OTHERS" "Disconnect" | \
    grep -v "^$" | wofi --dmenu --prompt "WiFi:" --width 300 --height 400 --no-actions)

[ -z "$MENU" ] && exit 0

if [ "$MENU" = "Disconnect" ]; then
    nmcli device disconnect "$WIFI_DEV"
    exit 0
fi

# Parse SSID: strip signal suffix and active marker
SSID=$(echo "$MENU" | sed 's/ \[[0-9]*%\]$//' | sed 's/^\* //')

# Find saved connection profile by SSID (not by profile name)
SAVED=$(nmcli -t -f name,802-11-wireless.ssid connection show 2>/dev/null | \
    awk -F: -v s="$SSID" '$2==s {print $1; exit}')

if [ -n "$SAVED" ]; then
    nmcli connection up id "$SAVED" && \
        notify-send "WiFi" "Connected to $SSID" || \
        notify-send "WiFi" "Failed to connect to $SSID"
else
    PASS=$(echo "" | wofi --dmenu --password --prompt "Password for '$SSID':" \
        --width 300 --height 80 --no-actions)
    [ $? -ne 0 ] && exit 0
    if [ -z "$PASS" ]; then
        nmcli device wifi connect "$SSID" && \
            notify-send "WiFi" "Connected to $SSID" || \
            notify-send "WiFi" "Failed to connect to $SSID"
    else
        nmcli device wifi connect "$SSID" password "$PASS" && \
            notify-send "WiFi" "Connected to $SSID" || \
            notify-send "WiFi" "Failed to connect to $SSID"
    fi
fi
