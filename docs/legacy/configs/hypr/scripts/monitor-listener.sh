#!/usr/bin/env bash

# Vérification de la présence de socat
if ! command -v socat &> /dev/null; then
    notify-send "Hyprland Monitor Listener" "socat n'est pas installé. Le script ne peut pas démarrer."
    exit 1
fi

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Vérification de la signature de l'instance
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    echo "HYPRLAND_INSTANCE_SIGNATURE non trouvée. Est-ce que Hyprland est lancé ?"
    exit 1
fi

# Écoute des événements monitoradded et monitorremoved
socat - UNIX-CONNECT:"$SOCKET" | while read -r line; do
    if echo "$line" | grep -qE "monitoradded|monitorremoved"; then
        ~/.config/hypr/scripts/set-workspaces.sh
    fi
done
