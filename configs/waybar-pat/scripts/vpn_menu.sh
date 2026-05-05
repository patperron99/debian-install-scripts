#!/bin/bash

# launch nm-apllet to use as polkit agent
# TODO replace by anther agent, tested so for wont work.
nm-applet &

# List all VPN connections
VPN_LIST=$(nmcli --terse --fields NAME,TYPE connection show | grep vpn | cut -d: -f1)

# Build the menu options
MENU=$(echo -e "$VPN_LIST\nDisconnect" | rofi -dmenu -p "VPN:" -theme nord)

# Exit if no option selected
if [ -z "$MENU" ]; then
  exit 0
elif [ "$MENU" = "Disconnect" ]; then
  # Disconnect all active VPN connections
  nmcli connection show --active | grep vpn | awk '{print $1}' | xargs -r -n1 nmcli connection down id
else
  # Connect to selected VPN
  nmcli connection up id "$MENU" && killall nm-applet
fi
