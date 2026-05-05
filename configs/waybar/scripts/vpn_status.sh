#!/bin/bash

# Get name of active VPN connection
VPN_NAME=$(nmcli --terse --fields NAME,TYPE connection show --active | grep vpn | cut -d: -f1)

if [ -n "$VPN_NAME" ]; then
  echo "󱇱 $VPN_NAME"
else
  echo " "
fi
