# Hyprland Installation for Debian

Guide d'installation de Hyprland sur Debian Testing/Sid avec configuration inspirée d'Omarchy.

Tous les packages sont installés via APT — aucune compilation requise.

## Prérequis

- Debian Testing (Forky) ou Sid (Unstable)
- Connexion Internet
- Droits sudo

## Scripts disponibles

### 1. `scripts/install-hyprland.sh`
Installation complète de l'écosystème Hyprland depuis les dépôts APT.
Les sources Sid sont ajoutées automatiquement si nécessaire, avec pinning APT configuré.

### 2. `scripts/setup-hyprland-config.sh`
Génère une configuration modulaire Hyprland inspirée d'Omarchy.

## Installation rapide

```bash
# 1. Lancer l'installation (sources Sid ajoutées automatiquement si besoin)
bash scripts/install-hyprland.sh

# 2. Configurer Hyprland
bash scripts/setup-hyprland-config.sh
```

## Statut des packages

### ✅ Disponibles dans Debian Testing (Forky)

- **Utilitaires Wayland** : waybar, wofi, swaybg, grim, slurp, wl-clipboard
- **Notifications** : mako-notifier
- **Audio** : pipewire, pipewire-pulse, wireplumber, pamixer
- **Réseau** : iwd
- **Fichiers** : nautilus, gnome-disk-utility
- **Visionneuses** : evince, imv
- **Polices** : fonts-noto, fonts-font-awesome, fonts-jetbrains-mono
- **Terminal** : alacritty
- **Système** : brightnessctl, playerctl, hyprpolkitagent, sddm
- **Médias** : mpv, imagemagick

### ⚠️ Disponibles depuis Sid (ajoutés automatiquement)

- `hyprland`
- `xdg-desktop-portal-hyprland`
- `hyprlock` (écran de verrouillage)
- `hypridle` (daemon de veille)
- `hyprpicker` (pipette couleur)
- `swayosd` (OSD volume/luminosité)

## Structure de configuration

La configuration est modulaire, inspirée d'Omarchy :

```
~/.config/hypr/
├── hyprland.conf      # Fichier principal (source les autres)
├── envs.conf          # Variables d'environnement
├── monitors.conf      # Configuration des écrans
├── input.conf         # Clavier, souris, touchpad
├── looknfeel.conf     # Apparence (gaps, bordures, animations)
├── bindings.conf      # Raccourcis clavier
├── autostart.conf     # Applications au démarrage
└── windowrules.conf   # Règles pour les fenêtres

~/.config/waybar/
├── config             # Configuration de la barre
└── style.css          # Style CSS
```

## Raccourcis clavier par défaut

### Applications
- `SUPER + Return` - Terminal (alacritty)
- `SUPER + D` - Lanceur d'applications (wofi)
- `SUPER + E` - Gestionnaire de fichiers (nautilus)
- `SUPER + Q` - Fermer la fenêtre active
- `SUPER + L` - Verrouiller l'écran (hyprlock)
- `SUPER + B` - Bluetooth (blueman-manager)
- `SUPER + SHIFT + A` - Volume (pavucontrol)

### Système
- `SUPER + SHIFT + P` - Menu power (lock/logout/suspend/reboot/shutdown)
- `SUPER + W` - Prochain wallpaper (cycle)
- `SUPER + SHIFT + T` - Sélecteur de thème (Catppuccin / Tokyo Night / Gruvbox / Nord / Rose Pine)
- `SUPER + C` - Historique presse-papiers (cliphist + wofi)
- `SUPER + SHIFT + C` - Pipette couleur (hyprpicker)
- `SUPER + SHIFT + R` - Enregistrement écran (wf-recorder toggle)

### Fenêtres
- `SUPER + F` - Plein écran
- `SUPER + V` - Toggle floating
- `SUPER + J` - Toggle split
- `SUPER + flèches` - Déplacer le focus
- `SUPER + h/j/k/l` - Déplacer le focus (vim)

### Espaces de travail
- `SUPER + 1-9` - Aller à l'espace de travail 1-9
- `SUPER + SHIFT + 1-9` - Déplacer la fenêtre vers l'espace 1-9
- `SUPER + Molette` - Naviguer entre espaces

### Multimédia
- `XF86AudioRaiseVolume` - Volume +
- `XF86AudioLowerVolume` - Volume -
- `XF86AudioMute` - Mute
- `XF86AudioPlay` - Play/Pause
- `XF86MonBrightnessUp` - Luminosité +
- `XF86MonBrightnessDown` - Luminosité -

### Screenshots
- `Print` - Screenshot d'une zone (copié dans presse-papiers)
- `SHIFT + Print` - Screenshot complet (copié dans presse-papiers)
- `SUPER + Print` - Screenshot sauvegardé dans ~/Pictures/

## Personnalisation

### Modifier les raccourcis
Éditez `~/.config/hypr/bindings.conf` et rechargez Hyprland (auto-reload à la sauvegarde).

### Configurer les écrans
Éditez `~/.config/hypr/monitors.conf`. Exemple :
```conf
monitor = eDP-1, 1920x1080@60, 0x0, 1
monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1
```

### Modifier l'apparence
Éditez `~/.config/hypr/looknfeel.conf` pour :
- Gaps (espaces entre fenêtres)
- Bordures et couleurs
- Animations
- Blur et effets

### Changer le fond d'écran
Placez votre image dans `~/Pictures/wallpaper.png` ou éditez `~/.config/hypr/autostart.conf`

### Personnaliser Waybar
- Layout : `~/.config/waybar/config`
- Style : `~/.config/waybar/style.css`
- Redémarrer : `killall waybar && waybar &`

## Dépannage

### Hyprland ne démarre pas
```bash
# Vérifier les logs
cat /var/log/hyprland-install.log

# Vérifier que Hyprland est installé
which Hyprland
Hyprland --version
```

### Packages manquants après installation
```bash
# Installer depuis Sid explicitement
sudo apt install -t sid hyprland xdg-desktop-portal-hyprland hyprlock hypridle
```

### Waybar ne s'affiche pas
```bash
ps aux | grep waybar
killall waybar
waybar &
```

### Problèmes de performances
Éditez `~/.config/hypr/looknfeel.conf` :
```conf
animations {
    enabled = false
}

decoration {
    blur {
        enabled = false
    }
}
```

### Écran noir après login
```bash
# Depuis un autre TTY (Ctrl+Alt+F2)
cat ~/.local/share/hyprland/hyprland.log

# Réinitialiser la config
mv ~/.config/hypr ~/.config/hypr.backup
bash scripts/setup-hyprland-config.sh
```

## Mise à jour

```bash
sudo apt update
sudo apt upgrade
```

## Désinstallation

```bash
# Packages APT
sudo apt remove hyprland waybar wofi hyprlock hypridle

# Configuration
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
```

## Ressources

- [Wiki Hyprland](https://wiki.hyprland.org/)
- [Omarchy](https://omarchy.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
- [r/hyprland](https://www.reddit.com/r/hyprland/)

## Inspirations

- **Omarchy** — Structure modulaire et organisation
- **JaKooLit/Debian-Hyprland** — Scripts d'installation
- **Hyprland defaults** — Configuration de base

## Licence

Scripts sous MIT License. Configurations sous CC0 (domaine public).
