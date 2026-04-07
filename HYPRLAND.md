# Hyprland Installation for Debian

Guide d'installation de Hyprland sur Debian Testing/Sid avec configuration inspirée d'Omarchy.

## Prérequis

- Debian Testing (Forky) ou Sid (Unstable)
- Connexion Internet
- Droits sudo

## Scripts disponibles

### 1. `scripts/install-hyprland.sh`
Script principal d'installation avec deux options :
- **Option 1** : Installation depuis les dépôts Sid/Unstable (rapide, recommandé)
- **Option 2** : Compilation depuis les sources (plus long, versions récentes)

### 2. `scripts/compile-hyprland-sources.sh`
Script de compilation des packages depuis les sources GitHub. Peut être exécuté indépendamment.

### 3. `scripts/setup-hyprland-config.sh`
Génère une configuration modulaire Hyprland inspirée d'Omarchy.

## Installation rapide

### Méthode 1 : Depuis les dépôts (recommandé)

```bash
# 1. Ajouter les sources Sid (si nécessaire)
echo 'deb http://deb.debian.org/debian/ sid main contrib non-free' | sudo tee /etc/apt/sources.list.d/sid.list

# 2. Configurer les priorités APT (optionnel mais recommandé)
sudo tee /etc/apt/preferences.d/sid.pref << EOF
Package: *
Pin: release a=testing
Pin-Priority: 900

Package: *
Pin: release a=sid
Pin-Priority: 100
EOF

# 3. Lancer l'installation
sudo apt update
bash scripts/install-hyprland.sh
# Sélectionner l'option 1

# 4. Configurer Hyprland
bash scripts/setup-hyprland-config.sh
```

### Méthode 2 : Compilation depuis sources

```bash
# 1. Lancer l'installation
bash scripts/install-hyprland.sh
# Sélectionner l'option 2

# 2. Configurer Hyprland
bash scripts/setup-hyprland-config.sh
```

### Méthode 3 : Compilation manuelle

```bash
# Installer uniquement les packages des dépôts
bash scripts/install-hyprland.sh
# Sélectionner l'option 1

# Compiler uniquement certains packages
bash scripts/compile-hyprland-sources.sh
# Choisir les packages à compiler

# Configurer
bash scripts/setup-hyprland-config.sh
```

## Statut des packages

### ✅ Disponibles dans Debian Testing/Sid

Ces packages s'installent directement via APT :

- **Wayland** : xwayland
- **Utilitaires** : waybar, wofi, dunst, rofi
- **Sway** : swaybg, swaylock, swayidle
- **Screenshots** : grim, slurp
- **Clipboard** : wl-clipboard
- **Audio** : pipewire, pipewire-pulse, wireplumber, pavucontrol
- **Réseau** : network-manager, blueman
- **Fichiers** : thunar + plugins
- **Polices** : fonts-noto, fonts-font-awesome, fonts-jetbrains-mono
- **Terminaux** : kitty, alacritty
- **Système** : brightnessctl, playerctl, polkitd

### ⚠️ Disponibles uniquement dans Sid

Ces packages nécessitent les sources Sid :

- `hyprland`
- `xdg-desktop-portal-hyprland`

### 🔨 Nécessitent compilation

Ces packages doivent être compilés depuis les sources :

- `hyprpaper` (gestionnaire de fond d'écran)
- `hypridle` (daemon de veille)
- `hyprlock` (écran de verrouillage)
- `swww` (fonds d'écran animés)
- `cliphist` (historique du presse-papiers)

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
- `SUPER + Return` - Terminal (kitty)
- `SUPER + D` - Lanceur d'applications (wofi)
- `SUPER + E` - Gestionnaire de fichiers (thunar)
- `SUPER + Q` - Fermer la fenêtre active
- `SUPER + L` - Verrouiller l'écran

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

# Tester en mode debug
Hyprland --version
```

### Packages manquants après installation
```bash
# Recompiler manuellement
bash scripts/compile-hyprland-sources.sh

# Ou installer depuis Sid
sudo apt install -t sid hyprland xdg-desktop-portal-hyprland
```

### Waybar ne s'affiche pas
```bash
# Vérifier le processus
ps aux | grep waybar

# Relancer
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
# Vérifier les logs Hyprland
cat ~/.local/share/hyprland/hyprland.log

# Réinitialiser la config
mv ~/.config/hypr ~/.config/hypr.backup
bash scripts/setup-hyprland-config.sh
```

## Mise à jour

### Packages des dépôts
```bash
sudo apt update
sudo apt upgrade
```

### Packages compilés
```bash
# Recompiler depuis les sources
cd ~/.local/src/hyprland-build
bash ~/Work/debian-install-scripts/scripts/compile-hyprland-sources.sh
```

## Désinstallation

### Packages APT
```bash
sudo apt remove hyprland waybar wofi # etc.
```

### Packages compilés
```bash
# Supprimer les binaires
sudo rm /usr/local/bin/{Hyprland,hyprlock,hypridle,hyprpaper,swww,cliphist}

# Supprimer les bibliothèques
sudo rm -rf /usr/local/lib/libhypr*
sudo ldconfig

# Supprimer les sources
rm -rf ~/.local/src/hyprland-build
```

### Configuration
```bash
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
```

## Ressources

- [Wiki Hyprland](https://wiki.hyprland.org/)
- [Omarchy](https://omarchy.org/)
- [Waybar Wiki](https://github.com/Alexays/Waybar/wiki)
- [r/hyprland](https://www.reddit.com/r/hyprland/)

## Inspirations

Cette configuration est inspirée de :
- **Omarchy** - Structure modulaire et organisation
- **JaKooLit/Debian-Hyprland** - Scripts de compilation
- **Hyprland defaults** - Configuration de base

## Licence

Scripts sous MIT License. Configurations sous CC0 (domaine public).
