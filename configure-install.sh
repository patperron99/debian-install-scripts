#!/bin/bash
# configure-install.sh — Collecte toute la configuration d'installation en une seule session.
# Génère install.conf (vars non-sensibles) et .install-passwords (secrets, chmod 600).
# Usage : bash configure-install.sh  →  bash debian-install-fresh.sh

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    error "Lancer en tant que root : sudo bash configure-install.sh"
fi

# ── Installer gum ─────────────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
    log "Installation de gum (Charm)..."
    apt-get update -qq
    apt-get install -y -qq curl gpg
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
        > /etc/apt/sources.list.d/charm.list
    apt-get update -qq && apt-get install -y -qq gum || error "Impossible d'installer gum"
fi

# ── Styles communs gum ────────────────────────────────────────────────────────
C=212  # couleur principale (mauve Charm)

_choose() { gum choose \
    --selected.foreground "$C" --cursor.foreground "$C" \
    --header.foreground "$C" "$@"; }

_filter() { gum filter \
    --indicator.foreground "$C" --match.foreground "$C" \
    --prompt.foreground "$C" --placeholder.foreground 240 \
    --height 18 "$@"; }

_input() { gum input \
    --prompt.foreground "$C" --cursor.foreground "$C" \
    --placeholder.foreground 240 "$@"; }

_confirm() { gum confirm \
    --selected.foreground 0 --selected.background "$C" \
    --unselected.foreground 252 "$@"; }

_section() {
    echo ""
    gum style --foreground "$C" --bold "── $1 ──"
    echo ""
}

_pass() {
    local label="$1" _p1 _p2
    while true; do
        _p1=$(gum input --password --prompt "$label : " \
            --prompt.foreground "$C" --cursor.foreground "$C")
        if [ -z "$_p1" ]; then
            echo "  Mot de passe vide — réessayer." >&2
            continue
        fi
        _p2=$(gum input --password --prompt "Confirmer : " \
            --prompt.foreground "$C" --cursor.foreground "$C")
        [ "$_p1" = "$_p2" ] && { echo "$_p1"; return; }
        echo "  Les mots de passe ne correspondent pas — réessayer." >&2
    done
}

# ══════════════════════════════════════════════════════════════════════════════
clear
gum style \
    --border double --border-foreground "$C" \
    --padding "1 4" --margin "1 2" \
    --bold --foreground "$C" \
    "  Configuration d'installation Debian  "

gum style --foreground 252 \
    "Ce script collecte toute la configuration en une seule session." \
    "Les scripts d'installation s'exécuteront ensuite sans interruption."

# ── 1. Disque ─────────────────────────────────────────────────────────────────
_section "1/9  Disque cible"

mapfile -t _disks < <(lsblk -d -n -p -o NAME,SIZE,MODEL | grep -E '^/dev/(sd|vd|nvme)')
[ ${#_disks[@]} -eq 0 ] && error "Aucun disque trouvé (sd*, vd*, nvme*)"

INSTALL_DISK=$(printf '%s\n' "${_disks[@]}" | \
    _filter --placeholder "Taper pour filtrer, Entrée pour sélectionner..." | \
    awk '{print $1}')
[ -z "$INSTALL_DISK" ] && error "Aucun disque sélectionné."
log "Disque : $INSTALL_DISK"

# ── 2. Filesystem ─────────────────────────────────────────────────────────────
_section "2/9  Système de fichiers"

_fs_raw=$(_choose \
    --header "Choisir le système de fichiers :" \
    "btrfs  — subvolumes, snapshots, compression zstd (recommandé)" \
    "ext4   — classique, stable" \
    "xfs    — hautes performances, gros volumes")
[ -z "$_fs_raw" ] && error "Aucun filesystem sélectionné."
INSTALL_FS=$(awk '{print $1}' <<< "$_fs_raw")

if [ "$INSTALL_FS" = "btrfs" ]; then
    INSTALL_SNAPSHOTS="yes"
    INSTALL_SNAPSHOT_BOOT="yes"
else
    INSTALL_SNAPSHOTS="no"
    INSTALL_SNAPSHOT_BOOT="no"
fi
log "Filesystem : $INSTALL_FS"

# ── 3. LUKS ───────────────────────────────────────────────────────────────────
_section "3/9  Chiffrement LUKS2"

if _confirm "Chiffrer la partition root avec LUKS2 ?" --default=true; then
    INSTALL_LUKS="yes"
    log "LUKS : activé"
else
    INSTALL_LUKS="no"
    log "LUKS : désactivé"
fi

# ── 4. Release Debian ─────────────────────────────────────────────────────────
_section "4/9  Version Debian"

_rel_raw=$(_choose \
    --header "Choisir la version Debian :" \
    "stable  — Debian stable (recommandé)" \
    "testing — Debian testing (plus récent)")
INSTALL_RELEASE=$(awk '{print $1}' <<< "${_rel_raw:-stable}")
log "Release : $INSTALL_RELEASE"

# ── 5. Timezone ───────────────────────────────────────────────────────────────
_section "5/9  Fuseau horaire"

INSTALL_TIMEZONE=$(timedatectl list-timezones | \
    _filter --placeholder "Taper pour filtrer  ex: America/Montreal")
[ -z "$INSTALL_TIMEZONE" ] && INSTALL_TIMEZONE="America/Montreal"
log "Timezone : $INSTALL_TIMEZONE"

# ── 6. Locale ─────────────────────────────────────────────────────────────────
_section "6/9  Locale"

_locale_src=""
[ -f /usr/share/i18n/SUPPORTED ] && \
    _locale_src=$(grep -v '^#' /usr/share/i18n/SUPPORTED | awk '{print $1}' | sort -u)

INSTALL_LOCALE=""
if [ -n "$_locale_src" ]; then
    INSTALL_LOCALE=$(echo "$_locale_src" | \
        _filter --placeholder "Taper pour filtrer  ex: fr_FR.UTF-8")
fi
[ -z "$INSTALL_LOCALE" ] && INSTALL_LOCALE="fr_FR.UTF-8"
log "Locale : $INSTALL_LOCALE"

# ── 7. Hostname & Username ────────────────────────────────────────────────────
_section "7/9  Identifiants machine"

INSTALL_HOSTNAME=$(_input --placeholder "debian" --prompt "Hostname : ")
INSTALL_HOSTNAME="${INSTALL_HOSTNAME:-debian}"

INSTALL_USERNAME=$(_input --placeholder "user" --prompt "Nom d'utilisateur : ")
INSTALL_USERNAME="${INSTALL_USERNAME:-user}"

log "Hostname : $INSTALL_HOSTNAME"
log "Username : $INSTALL_USERNAME"

# ── 8. WiFi ───────────────────────────────────────────────────────────────────
INSTALL_COPY_WIFI="no"
if [ -d /etc/NetworkManager/system-connections ] && \
   [ -n "$(ls -A /etc/NetworkManager/system-connections 2>/dev/null)" ]; then
    _section "8/9  Configuration WiFi"
    if _confirm "Copier la configuration WiFi du LiveCD vers la nouvelle installation ?" --default=true; then
        INSTALL_COPY_WIFI="yes"
        log "WiFi : copie activée"
    else
        log "WiFi : non copié"
    fi
else
    log "8/9  WiFi : aucune connexion NetworkManager détectée, étape ignorée"
fi

# ── 9. Mots de passe ──────────────────────────────────────────────────────────
_section "9/9  Mots de passe"

INSTALL_LUKS_PASS=""
if [ "$INSTALL_LUKS" = "yes" ]; then
    INSTALL_LUKS_PASS=$(_pass "Passphrase LUKS")
    log "Passphrase LUKS : définie"
fi

INSTALL_ROOT_PASS=$(_pass "Mot de passe root")
log "Mot de passe root : défini"

INSTALL_USER_PASS=$(_pass "Mot de passe '$INSTALL_USERNAME'")
log "Mot de passe utilisateur : défini"

# ── Résumé ────────────────────────────────────────────────────────────────────
echo ""
gum style \
    --border rounded --border-foreground "$C" \
    --padding "1 3" --margin "1 2" \
    "$(gum style --bold --foreground "$C" "Résumé de la configuration")" \
    "" \
    "$(printf "  %-22s %s" "Disque :"          "$INSTALL_DISK")" \
    "$(printf "  %-22s %s" "Filesystem :"      "$INSTALL_FS")" \
    "$(printf "  %-22s %s" "LUKS :"            "$INSTALL_LUKS")" \
    "$(printf "  %-22s %s" "Release :"         "$INSTALL_RELEASE")" \
    "$(printf "  %-22s %s" "Timezone :"        "$INSTALL_TIMEZONE")" \
    "$(printf "  %-22s %s" "Locale :"          "$INSTALL_LOCALE")" \
    "$(printf "  %-22s %s" "Hostname :"        "$INSTALL_HOSTNAME")" \
    "$(printf "  %-22s %s" "Username :"        "$INSTALL_USERNAME")" \
    "$(printf "  %-22s %s" "Copier WiFi :"     "$INSTALL_COPY_WIFI")" \
    "$(printf "  %-22s %s" "Snapshots btrfs :" "$INSTALL_SNAPSHOTS")" \
    "" \
    "$(gum style --foreground 240 "  Defaults : GTK=Adwaita  Curseur=Adwaita  Thème=gruvbox  Plymouth=spinner  Neovim=yes")"

echo ""
gum style --foreground 196 --bold "  ATTENTION : $INSTALL_DISK sera entièrement effacé lors de l'installation."
echo ""
_confirm "Confirmer et écrire la configuration ?" --default=false \
    || { echo "Annulé."; exit 0; }

# ── Écriture install.conf ─────────────────────────────────────────────────────
cat > "$SCRIPT_DIR/install.conf" << EOF
# install.conf — Généré par configure-install.sh le $(date '+%Y-%m-%d %H:%M')
# Éditable manuellement. Ne contient PAS de mots de passe.

# ── Installation ──────────────────────────────────────────────────────────────
INSTALL_DISK=$INSTALL_DISK
INSTALL_FS=$INSTALL_FS
INSTALL_LUKS=$INSTALL_LUKS
INSTALL_RELEASE=$INSTALL_RELEASE
INSTALL_COPY_WIFI=$INSTALL_COPY_WIFI

# ── Système ───────────────────────────────────────────────────────────────────
INSTALL_HOSTNAME=$INSTALL_HOSTNAME
INSTALL_USERNAME=$INSTALL_USERNAME
INSTALL_LOCALE=$INSTALL_LOCALE
INSTALL_TIMEZONE=$INSTALL_TIMEZONE

# ── Interface ─────────────────────────────────────────────────────────────────
INSTALL_GTK_THEME=Adwaita
INSTALL_CURSOR_THEME=Adwaita
INSTALL_CURSOR_SIZE=24
INSTALL_COLOR_THEME=gruvbox
INSTALL_NEOVIM_SETUP=yes
INSTALL_PLYMOUTH_THEME=spinner

# ── Fonctionnalités ───────────────────────────────────────────────────────────
INSTALL_AUTO_UPDATES=yes
INSTALL_SNAPSHOTS=$INSTALL_SNAPSHOTS
INSTALL_SNAPSHOT_BOOT=$INSTALL_SNAPSHOT_BOOT
EOF
chmod 644 "$SCRIPT_DIR/install.conf"

# ── Écriture .install-passwords ───────────────────────────────────────────────
{
    declare -p INSTALL_LUKS_PASS
    declare -p INSTALL_ROOT_PASS
    declare -p INSTALL_USER_PASS
} > "$SCRIPT_DIR/.install-passwords"
chmod 600 "$SCRIPT_DIR/.install-passwords"

echo ""
log "install.conf écrit       : $SCRIPT_DIR/install.conf"
log ".install-passwords écrit : $SCRIPT_DIR/.install-passwords (chmod 600)"
echo ""
gum style --foreground "$C" --bold "Configuration complète."
echo ""
gum style --foreground 252 "Lancer l'installation :" \
    "  bash debian-install-fresh.sh"
echo ""
