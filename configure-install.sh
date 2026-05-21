#!/bin/bash
# configure-install.sh — Collecte toute la configuration d'installation en une seule session.
# Génère install.conf (vars non-sensibles) et .install-passwords (secrets, chmod 600).
# Usage : bash configure-install.sh  →  bash debian-install-fresh.sh

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
header() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}"; }
ask()    { echo -e "${BLUE}$1${NC}"; }

# ── Root check ────────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    error "Lancer en tant que root : sudo bash configure-install.sh"
fi

# ── fzf ───────────────────────────────────────────────────────────────────────
if ! command -v fzf &>/dev/null; then
    log "Installation de fzf..."
    apt-get update -qq && apt-get install -y -qq fzf || error "Impossible d'installer fzf"
fi

# ── Helper : prompt avec défaut ───────────────────────────────────────────────
prompt_default() {
    local label="$1" default="$2"
    ask "${label} [${default}] : "
    read -r _val
    echo "${_val:-$default}"
}

# ── Helper : confirmation y/N ─────────────────────────────────────────────────
prompt_yn() {
    local label="$1" default="${2:-n}"
    local indicator
    if [[ "${default,,}" == "y" ]]; then indicator="Y/n"; else indicator="y/N"; fi
    ask "${label} (${indicator}) : "
    read -r _yn
    if [ -z "$_yn" ]; then _yn="$default"; fi
    [[ "${_yn,,}" =~ ^(y|yes)$ ]]
}

# ── Helper : double password ──────────────────────────────────────────────────
prompt_password() {
    local label="$1"
    local _p1 _p2
    while true; do
        ask "${label} : "
        read -rsp "" _p1; echo
        ask "Confirmer : "
        read -rsp "" _p2; echo
        if [ "$_p1" = "$_p2" ]; then
            echo "$_p1"
            return
        fi
        warn "Les mots de passe ne correspondent pas. Réessayer."
    done
}

# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║     Configuration d'installation Debian          ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "Ce script collecte toute la configuration nécessaire."
echo "Les scripts d'installation s'exécuteront ensuite sans interruption."
echo ""

# ── 1. Disque ─────────────────────────────────────────────────────────────────
header "1/9  Disque cible"

mapfile -t _disks < <(lsblk -d -n -p -o NAME,SIZE,MODEL | grep -E '^/dev/(sd|vd|nvme)')
if [ ${#_disks[@]} -eq 0 ]; then
    error "Aucun disque trouvé (sd*, vd*, nvme*)"
fi

INSTALL_DISK=$(printf '%s\n' "${_disks[@]}" | \
    fzf --prompt="  Sélectionner le disque d'installation > " \
        --height=10 --border --no-sort | \
    awk '{print $1}')
[ -z "$INSTALL_DISK" ] && error "Aucun disque sélectionné."
log "Disque : $INSTALL_DISK"

# ── 2. Filesystem ─────────────────────────────────────────────────────────────
header "2/9  Système de fichiers"
echo "  1) btrfs  — subvolumes, snapshots, compression zstd (recommandé)"
echo "  2) ext4   — classique, stable"
echo "  3) xfs    — hautes performances, gros volumes"
echo ""
ask "Choix [1] : "
read -r _fs_choice
case "${_fs_choice:-1}" in
    2) INSTALL_FS="ext4" ;;
    3) INSTALL_FS="xfs" ;;
    *) INSTALL_FS="btrfs" ;;
esac
log "Filesystem : $INSTALL_FS"

# Snapshots uniquement si btrfs
if [ "$INSTALL_FS" = "btrfs" ]; then
    INSTALL_SNAPSHOTS="yes"
    INSTALL_SNAPSHOT_BOOT="yes"
else
    INSTALL_SNAPSHOTS="no"
    INSTALL_SNAPSHOT_BOOT="no"
fi

# ── 3. LUKS ───────────────────────────────────────────────────────────────────
header "3/9  Chiffrement LUKS2"
if prompt_yn "Chiffrer la partition root avec LUKS2 ?" "y"; then
    INSTALL_LUKS="yes"
    log "LUKS : activé"
else
    INSTALL_LUKS="no"
    log "LUKS : désactivé"
fi

# ── 4. Release Debian ─────────────────────────────────────────────────────────
header "4/9  Version Debian"
echo "  1) stable   — Debian stable (recommandé)"
echo "  2) testing  — Debian testing (plus récent)"
echo ""
ask "Choix [1] : "
read -r _rel_choice
case "${_rel_choice:-1}" in
    2) INSTALL_RELEASE="testing" ;;
    *) INSTALL_RELEASE="stable" ;;
esac
log "Release : $INSTALL_RELEASE"

# ── 5. Timezone ───────────────────────────────────────────────────────────────
header "5/9  Fuseau horaire"
INSTALL_TIMEZONE=$(timedatectl list-timezones | \
    fzf --prompt="  Fuseau horaire > " \
        --query="America/" \
        --height=20 --border)
[ -z "$INSTALL_TIMEZONE" ] && INSTALL_TIMEZONE="America/Montreal"
log "Timezone : $INSTALL_TIMEZONE"

# ── 6. Locale ─────────────────────────────────────────────────────────────────
header "6/9  Locale"
_locale_list=""
if [ -f /usr/share/i18n/SUPPORTED ]; then
    _locale_list=$(grep -v '^#' /usr/share/i18n/SUPPORTED | awk '{print $1}' | sort -u)
elif [ -f /usr/share/locale/locale.alias ]; then
    _locale_list=$(grep -v '^#' /usr/share/locale/locale.alias | awk '{print $2}' | sort -u)
fi

if [ -n "$_locale_list" ]; then
    INSTALL_LOCALE=$(echo "$_locale_list" | \
        fzf --prompt="  Locale > " \
            --query="fr_FR" \
            --height=20 --border)
fi
[ -z "$INSTALL_LOCALE" ] && INSTALL_LOCALE="fr_FR.UTF-8"
log "Locale : $INSTALL_LOCALE"

# ── 7. Hostname & Username ────────────────────────────────────────────────────
header "7/9  Identifiants machine"
INSTALL_HOSTNAME=$(prompt_default "Hostname" "debian")
INSTALL_USERNAME=$(prompt_default "Nom d'utilisateur" "user")
log "Hostname : $INSTALL_HOSTNAME"
log "Username : $INSTALL_USERNAME"

# ── 8. WiFi ───────────────────────────────────────────────────────────────────
INSTALL_COPY_WIFI="no"
if [ -d /etc/NetworkManager/system-connections ] && \
   [ -n "$(ls -A /etc/NetworkManager/system-connections 2>/dev/null)" ]; then
    header "8/9  Configuration WiFi"
    if prompt_yn "Copier la configuration WiFi du LiveCD vers la nouvelle installation ?" "y"; then
        INSTALL_COPY_WIFI="yes"
        log "WiFi : copie activée"
    else
        log "WiFi : non copié"
    fi
else
    log "8/9  WiFi : aucune connexion NetworkManager détectée, étape ignorée"
fi

# ── 9. Mots de passe ──────────────────────────────────────────────────────────
header "9/9  Mots de passe"

INSTALL_LUKS_PASS=""
if [ "$INSTALL_LUKS" = "yes" ]; then
    INSTALL_LUKS_PASS=$(prompt_password "Passphrase LUKS")
    log "Passphrase LUKS : définie"
fi

INSTALL_ROOT_PASS=$(prompt_password "Mot de passe root")
log "Mot de passe root : défini"

INSTALL_USER_PASS=$(prompt_password "Mot de passe pour '$INSTALL_USERNAME'")
log "Mot de passe utilisateur : défini"

# ── Résumé ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}══ Résumé de la configuration ══${NC}"
echo ""
printf "  %-24s %s\n" "Disque :"           "$INSTALL_DISK"
printf "  %-24s %s\n" "Filesystem :"       "$INSTALL_FS"
printf "  %-24s %s\n" "LUKS :"             "$INSTALL_LUKS"
printf "  %-24s %s\n" "Release Debian :"   "$INSTALL_RELEASE"
printf "  %-24s %s\n" "Timezone :"         "$INSTALL_TIMEZONE"
printf "  %-24s %s\n" "Locale :"           "$INSTALL_LOCALE"
printf "  %-24s %s\n" "Hostname :"         "$INSTALL_HOSTNAME"
printf "  %-24s %s\n" "Username :"         "$INSTALL_USERNAME"
printf "  %-24s %s\n" "Copier WiFi :"      "$INSTALL_COPY_WIFI"
printf "  %-24s %s\n" "Snapshots btrfs :"  "$INSTALL_SNAPSHOTS"
echo ""
echo -e "  ${YELLOW}Defaults silencieux appliqués :${NC}"
printf "  %-24s %s\n" "GTK theme :"        "Adwaita"
printf "  %-24s %s\n" "Curseur :"          "Adwaita"
printf "  %-24s %s\n" "Thème couleur :"    "gruvbox"
printf "  %-24s %s\n" "Neovim :"           "yes"
printf "  %-24s %s\n" "Plymouth :"         "spinner"
printf "  %-24s %s\n" "Auto-updates :"     "yes"
echo ""

warn "ATTENTION : $INSTALL_DISK sera entièrement effacé lors de l'installation."
echo ""
ask "Confirmer et écrire la configuration ? (y/N) : "
read -r _confirm
if [[ ! "${_confirm,,}" =~ ^(y|yes)$ ]]; then
    echo "Annulé."
    exit 0
fi

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
log "install.conf écrit           : $SCRIPT_DIR/install.conf"
log ".install-passwords écrit     : $SCRIPT_DIR/.install-passwords (chmod 600)"
echo ""
echo -e "${BOLD}${GREEN}Configuration complète.${NC}"
echo ""
echo "Lancer l'installation :"
echo -e "  ${CYAN}bash debian-install-fresh.sh${NC}"
echo ""
