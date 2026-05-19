#!/bin/bash

LINE=$(pritunl-client list 2>/dev/null | awk -F'|' '/Active/ {print}' | head -1)

if [ -n "$LINE" ]; then
    NAME=$(echo "$LINE"   | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
    UPTIME=$(echo "$LINE" | awk -F'|' '{gsub(/^ +| +$/, "", $6); print $6}')
    SERVER=$(echo "$LINE" | awk -F'|' '{gsub(/^ +| +$/, "", $7); print $7}')
    CLIENT=$(echo "$LINE" | awk -F'|' '{gsub(/^ +| +$/, "", $8); print $8}')
    printf '{"text":"󱇱","tooltip":"%s\\n%s → %s\\nUptime: %s","class":"connected"}\n' \
        "$NAME" "$SERVER" "$CLIENT" "$UPTIME"
else
    printf '{"text":"󱇱","tooltip":"VPN disconnected","class":"disconnected"}\n'
fi
