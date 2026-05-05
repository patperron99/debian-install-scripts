# Status des packages Hyprland sur Debian

Dernière vérification : Avril 2026

## Packages testés et validés

### ✅ Disponibles dans Debian Testing (Forky) et Sid

| Package | Testing | Sid | Notes |
|---------|---------|-----|-------|
| waybar | ✅ v0.12.0+ | ✅ | Fonctionne parfaitement |
| wofi | ✅ | ✅ | Alternative à rofi |
| rofi | ✅ | ✅ | Version wayland disponible |
| dunst | ✅ | ✅ | Notifications |
| mako-notifier | ✅ | ✅ | Alternative à dunst |
| swaybg | ✅ | ✅ | Fond d'écran simple |
| swaylock | ✅ | ✅ | Verrouillage écran |
| swayidle | ✅ | ✅ | Gestion de l'idle |
| grim | ✅ | ✅ | Screenshots |
| slurp | ✅ | ✅ | Sélection de zone |
| wl-clipboard | ✅ | ✅ | Presse-papiers |
| xwayland | ✅ | ✅ | Support X11 |
| pipewire | ✅ | ✅ | Audio |
| pipewire-pulse | ✅ | ✅ | Compatibilité PulseAudio |
| pipewire-audio | ✅ | ✅ | Plugins audio |
| wireplumber | ✅ | ✅ | Session manager |
| pavucontrol | ✅ | ✅ | Contrôle volume GUI |
| network-manager | ✅ | ✅ | Gestion réseau |
| network-manager-gnome | ✅ | ✅ | Applet réseau |
| blueman | ✅ | ✅ | Gestion bluetooth |
| thunar | ✅ | ✅ | Gestionnaire de fichiers |
| kitty | ✅ | ✅ | Terminal |
| alacritty | ✅ | ✅ | Terminal |
| brightnessctl | ✅ | ✅ | Contrôle luminosité |
| playerctl | ✅ | ✅ | Contrôle média |
| polkitd | ✅ | ✅ | Agent d'authentification |
| qt5ct | ✅ | ✅ | Configuration Qt5 |
| kvantum | ✅ | ✅ | Thème Qt |
| fonts-noto | ✅ | ✅ | Police système |
| fonts-font-awesome | ✅ | ✅ | Icônes |
| fonts-jetbrains-mono | ✅ | ✅ | Police monospace |

### ⚠️ Disponibles uniquement dans Sid

| Package | Testing | Sid | Notes |
|---------|---------|-----|-------|
| hyprland | ❌ (retiré) | ✅ v0.54+ | Nécessite sources Sid |
| xdg-desktop-portal-hyprland | ❌ | ✅ | Nécessite sources Sid |
| hyprlock | ❌ | ✅ | Verrouillage écran Hyprland-natif |
| hypridle | ❌ | ✅ | Daemon de veille |
| hyprpicker | ❌ | ✅ | Pipette couleur |
| swayosd | ❌/✅ | ✅ | OSD volume/luminosité |
| swaybg | ❌ | ✅ | Gestionnaire de fond d'écran |
| cliphist | ❌ | ✅ | Historique presse-papiers |

**Note importante** : Hyprland a été temporairement retiré de Trixie mais est disponible dans Forky (nouvelle branche testing) et Sid. Le script `install-hyprland.sh` ajoute les sources Sid automatiquement si nécessaire, avec pinning APT configuré.

### ✅ Disponibles dans Forky (ajouts récents)

| Package | Notes |
|---------|-------|
| kanshi | Multi-monitor automatique (profiles) |
| wf-recorder | Enregistrement écran Wayland |
| swayimg | Visionneuse d'images légère |
| nwg-look | Configurateur GTK pour Wayland |
| arc-theme | Thème GTK flat/dark |
| papirus-icon-theme | Thème d'icônes |
| bibata-cursor-theme | Thème de curseur (si disponible) |
| breeze-cursor-theme | Thème de curseur KDE |
| qt5ct | Configurateur Qt5 |
| adwaita-qt | Style Qt compatible GTK |
| xsettingsd | Daemon de paramètres GTK pour Wayland |

### 🚫 Non disponibles dans APT Debian

| Package | Alternative | Raison |
|---------|-------------|--------|
| swww | swaybg | Nécessite Rust/cargo |
| walker | wofi | Nécessite compilation Go |
| bluetui | blueman | Nécessite Rust/cargo |

### ❌ Packages inexistants ou mal nommés

| Nom dans script original | Vrai nom / Alternative |
|---------------------------|------------------------|
| pipewire-audio | `pipewire-audio` ou séparé en plusieurs |
| polkit-kde-agent-1 | `polkitd` + agent séparé |
| qt6ct | Peut ne pas exister, utiliser `qt5ct` |
| waybar-experimental | N'existe pas dans Debian |
| grimblast | Pas dans repos, script shell simple |
| qt5-style-kvantum | Package s'appelle `kvantum` |

## Dépendances de compilation

Pour compiler Hyprland et composants depuis les sources :

```bash
# Outils de base
build-essential cmake meson ninja-build pkg-config git

# Bibliothèques Wayland
libwayland-dev wayland-protocols libdrm-dev libgbm-dev
libinput-dev libxkbcommon-dev libsystemd-dev

# Bibliothèques de rendu
libpixman-1-dev libseat-dev libcairo2-dev libpango1.0-dev
libjpeg-dev libwebp-dev

# Langages de programmation
golang-go        # Pour cliphist
cargo rustc      # Pour swww (installer via rustup)
```

## Notes par version Debian

### Debian Forky (Testing actuel - 2026)

- ✅ Hyprland v0.53+ disponible
- ✅ Waybar avec support Hyprland natif
- ✅ La plupart des dépendances présentes
- ⚠️ Certains packages récents nécessitent Sid

### Debian Sid (Unstable)

- ✅ Dernières versions de tous les packages
- ✅ Hyprland v0.54+
- ✅ Support complet de l'écosystème Hyprland
- ⚠️ Potentiellement instable

### Debian Trixie (ancienne Testing)

- ❌ Hyprland retiré en juin 2025
- ✅ Reste des packages Wayland disponibles
- ⚠️ Ne pas utiliser pour Hyprland

## Recommandations d'installation

### Pour utilisateurs novices
```bash
Option 1 : Dépôts Sid
- Plus rapide (15-30 min)
- Mises à jour via APT
- Stable pour une daily driver
```

### Pour tous les utilisateurs
```bash
Option unique : Dépôts APT (Forky + Sid)
- Rapide (15-30 min)
- Mises à jour via apt upgrade
- Stable pour daily driver
- Sid isolé par pinning APT (priorité 100)
```

## Sources vérifiées

- [packages.debian.org](https://packages.debian.org/)
- [Debian Package Tracker](https://tracker.debian.org/)
- Recherches Web : Mars-Avril 2026
- [JaKooLit/Debian-Hyprland](https://github.com/JaKooLit/Debian-Hyprland)
- Tests communautaires Debian Forums

## Changements récents

**2025-06** : Hyprland retiré de Trixie par les mainteneurs Debian
**2025-12** : Hyprland réintroduit dans Forky (nouvelle testing)
**2026-01** : Waybar 0.12+ avec support Hyprland natif
**2026-03** : Amélioration du packaging dans Sid

## Mise à jour de ce document

Pour vérifier l'état actuel des packages :

```bash
# Sur un système Debian
apt-cache policy hyprland
apt-cache search hypr

# En ligne
https://packages.debian.org/search?keywords=hyprland
```

Dernière mise à jour : 2026-04-28
