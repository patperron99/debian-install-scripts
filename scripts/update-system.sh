#!/bin/bash
# update-system.sh — Interactive system updater (apt + flatpak + GitHub binaries)

C=212  # mauve Charm

_section() {
    echo ""
    gum style --foreground "$C" --bold "── $1 ──"
    echo ""
}

_ok()   { gum style --foreground 2   "✓ $1"; }
_warn() { gum style --foreground 214 "  $1"; }

gum style \
    --border double --border-foreground "$C" \
    --padding "0 2" --margin "1 0" \
    --bold --foreground "$C" \
    "  Mise à jour du système"

echo ""
gum confirm \
    --selected.foreground 0 --selected.background "$C" \
    --unselected.foreground 252 \
    "Lancer les mises à jour ?" || exit 0

# ── APT ───────────────────────────────────────────────────────────────────────

_section "APT"

gum spin --title "Rafraîchissement des paquets..." -- sudo apt-get update -qq

APT_SIMULATE=$(apt-get -s upgrade 2>/dev/null)
APT_COUNT=$(echo "$APT_SIMULATE" | grep -c "^Inst")
APT_SECURITY=$(echo "$APT_SIMULATE" | grep -c "^Inst.*security")

if [ "$APT_COUNT" -eq 0 ]; then
    _ok "Aucune mise à jour APT disponible."
else
    SEC_MSG=""
    [ "$APT_SECURITY" -gt 0 ] && SEC_MSG=" (dont $APT_SECURITY de sécurité)"
    _warn "$APT_COUNT paquet(s) à mettre à jour$SEC_MSG."
    echo ""
    gum spin --title "Installation des mises à jour APT..." -- sudo apt-get upgrade -y
    _ok "APT mis à jour."
fi

# ── Flatpak ───────────────────────────────────────────────────────────────────

if command -v flatpak &>/dev/null; then
    _section "Flatpak"
    FLATPAK_COUNT=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
    if [ "$FLATPAK_COUNT" -eq 0 ]; then
        _ok "Aucune mise à jour Flatpak disponible."
    else
        _warn "$FLATPAK_COUNT application(s) à mettre à jour."
        echo ""
        gum spin --title "Mise à jour Flatpak..." -- flatpak update -y
        _ok "Flatpak mis à jour."
    fi
fi

# ── Binaires GitHub ───────────────────────────────────────────────────────────

_section "Binaires GitHub"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
"$SCRIPT_DIR/install-github-bins.sh"

# ── Redémarrage ───────────────────────────────────────────────────────────────

if [ -f /var/run/reboot-required ]; then
    echo ""
    gum style --foreground 196 --bold "⚠  Redémarrage requis"
    if [ -f /var/run/reboot-required.pkgs ]; then
        echo ""
        while IFS= read -r pkg; do
            gum style --foreground 240 "  $pkg"
        done < /var/run/reboot-required.pkgs
    fi
    echo ""
    if gum confirm \
        --selected.foreground 0 --selected.background "$C" \
        --unselected.foreground 252 \
        "Redémarrer maintenant ?"; then
        sudo reboot
    fi
fi

pkill -RTMIN+8 waybar 2>/dev/null || true

echo ""
read -rp "Appuyez sur Entrée pour fermer..."
