#!/bin/bash
# Point d'entrée depuis un live USB.
# Clone le repo et lance configure-install.sh.
#
# Usage :
#   bash <(curl -fsSL https://patperron99.github.io/debian-install-scripts/install.sh)
#
# Avec une branche spécifique :
#   BRANCH=sway bash <(curl -fsSL ...)

set -eo pipefail

REPO_URL="https://github.com/patperron99/debian-install-scripts.git"
BRANCH="${BRANCH:-main}"
DEST="/tmp/debian-install-scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
    error "Lancer en tant que root : sudo bash <(curl ...)"
fi

log "Mise à jour des paquets et installation de git..."
apt-get update -qq
apt-get install -y -qq git

if [ -d "$DEST" ]; then
    warn "Dossier $DEST déjà présent — suppression..."
    rm -rf "$DEST"
fi

log "Clonage de la branche '$BRANCH'..."
git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$DEST"

log "Lancement de configure-install.sh..."
exec bash "$DEST/configure-install.sh"
