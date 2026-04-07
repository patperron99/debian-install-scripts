# Configuration Hyprland 100% Wayland

Cette version des scripts est basée sur les packages utilisés par **Omarchy** et évite toutes les dépendances X11 qui peuvent tirer des environnements de bureau complets (Cinnamon, XFCE, etc.).

## Changements par rapport à la version précédente

### ❌ Packages RETIRÉS (tiraient des dépendances lourdes)

| Package retiré | Raison | Remplacement |
|----------------|--------|--------------|
| `thunar` + plugins | Tire XFCE | `nautilus` (Wayland natif) |
| `file-roller` | Archive manager GNOME | Intégré dans nautilus |
| `network-manager-gnome` | Tire GNOME/Cinnamon | `iwd` (gestion réseau pure) |
| `blueman` | Tire GTK desktop deps | CLI bluetooth ou à venir |
| `pavucontrol` | GUI mixer lourd | `pamixer` (CLI) |
| `dunst` | Notification X11 | `mako` (Wayland natif) |
| `rofi` | Même version wayland a deps X11 | `wofi` (Wayland pur) |
| `wofi` | Basique mais OK | Futur: walker (comme Omarchy) |
| `xwayland` | Support X11 optionnel | Retiré pour Wayland pur |

### ✅ Packages AJOUTÉS (Wayland-natifs, d'Omarchy)

| Package | Fonction | Notes |
|---------|----------|-------|
| `nautilus` | Gestionnaire fichiers | GNOME mais Wayland natif |
| `gnome-disk-utility` | Gestion disques | Wayland natif |
| `iwd` | Gestion WiFi/réseau | Remplace NetworkManager |
| `pamixer` | Contrôle audio CLI | PipeWire/PulseAudio |
| `mako-notifier` | Notifications | Wayland natif |
| `evince` | Lecteur PDF | GNOME mais Wayland natif |
| `imv` | Visionneuse images | Wayland natif |
| `policykit-1-gnome` | Authentification | Wayland support |
| `sddm` | Display manager | Wayland support |
| `qt5-wayland` | Support Qt Wayland | Pour apps Qt |
| `qt6-wayland` | Support Qt6 Wayland | Pour apps Qt6 |
| `avahi-daemon` | mDNS/zeroconf | Services réseau |
| `gvfs-backends` | Virtual filesystems | SMB, MTP, etc. |
| `gnome-keyring` | Gestion mots de passe | Wayland compatible |

### 🔨 Packages à COMPILER (écosystème Hyprland)

| Package | Fonction | Utilité |
|---------|----------|---------|
| `hypridle` | Gestion veille | Éteindre écran, lock auto |
| `hyprlock` | Écran verrouillage | Lock screen Hyprland |
| `hyprsunset` | Filtre lumière bleue | Night light mode |
| `hyprpicker` | Color picker | Pipette couleur Wayland |
| `swayosd` | OSD volume/brightness | Affichage visuel ajustements |

## Architecture Wayland-pure

### Gestion réseau : iwd

**Pourquoi iwd au lieu de NetworkManager ?**
- NetworkManager tire `network-manager-gnome` → tire Cinnamon/GNOME
- iwd est léger, moderne, Wayland-agnostic
- Configuration automatique DHCP/DNS via systemd-resolved

**Configuration** (automatique via script) :
```ini
# /etc/iwd/main.conf
[General]
EnableNetworkConfiguration=true
NameResolvingService=systemd

[Network]
EnableIPv6=true
```

**Utilisation** :
```bash
# Interface TUI
iwctl

# Lister réseaux
iwctl station wlan0 scan
iwctl station wlan0 get-networks

# Connecter
iwctl station wlan0 connect "SSID"
```

### Gestion audio : PipeWire + pamixer

**Pas de GUI mixer** pour éviter les dépendances desktop.

**Utilisation** :
```bash
# Volume
pamixer -i 5    # Augmenter 5%
pamixer -d 5    # Diminuer 5%
pamixer -t      # Toggle mute

# Afficher état
pamixer --get-volume
pamixer --get-mute
```

**Waybar** utilise pamixer via clic et scroll.

### Notifications : mako

**Wayland-natif**, pas de dépendances X11.

**Configuration** : `~/.config/mako/config`
```ini
max-visible=5
sort=-time
layer=overlay
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-radius=10
```

### Gestionnaire fichiers : nautilus

Oui, c'est GNOME, **MAIS** :
- Support Wayland natif complet
- Pas de dépendances X11
- N'installe PAS Cinnamon (contrairement à ce que Thunar peut faire via ses deps)
- Utilisé par Omarchy (distribution Wayland-pure)

**Alternatives légères possibles** :
- `nnn` (TUI, ultra-léger)
- `lf` (TUI, rapide)
- `pcmanfm-qt` (GUI Qt, mais peut tirer deps)

### Display manager : SDDM

**Support Wayland complet**, thèmes modernes disponibles.

Alternative : connexion en TTY puis `Hyprland` direct.

## Services systemd activés

```bash
iwd              # WiFi/réseau
bluetooth        # Bluetooth
sddm             # Display manager
avahi-daemon     # mDNS
```

**Pas de NetworkManager** - complètement remplacé par iwd.

## Vérifier l'installation 100% Wayland

### Aucun serveur X ne doit tourner

```bash
# Vérifier qu'aucun Xorg n'est en cours
ps aux | grep -i xorg
# Doit être vide

# Vérifier Wayland
echo $WAYLAND_DISPLAY
# Doit afficher: wayland-0 ou wayland-1

# Vérifier session
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type
# Doit afficher: Type=wayland
```

### Aucun environnement desktop parasité

```bash
# Vérifier packages Cinnamon/XFCE installés
dpkg -l | grep -i cinnamon
dpkg -l | grep -i xfce
# Doivent être vides

# Vérifier dépendances X11 minimales
dpkg -l | grep -i "x11-" | wc -l
# Devrait être très bas (< 10 packages système)
```

### Applications Wayland-natives uniquement

```bash
# Vérifier ce qui tourne
ps aux | grep -E "nautilus|alacritty|waybar|mako|hyprland"

# Toutes les fenêtres doivent utiliser Wayland
hyprctl clients | grep "xwayland: 1"
# Doit être vide si tout est Wayland
```

## Avantages de cette approche

### ✅ Performance
- Pas de serveur X en arrière-plan
- Pas de services desktop inutiles
- Moins de RAM utilisée (200-300 MB de moins)

### ✅ Cohérence
- Tout utilise les mêmes protocoles Wayland
- Pas de mélange X11/Wayland
- Gestion d'entrée unifiée

### ✅ Sécurité
- Pas de X11 (protocole moins sécurisé)
- Isolation des fenêtres
- Capture d'écran contrôlée par portals

### ✅ Modernité
- HiDPI natif
- VRR/Adaptive Sync
- Gestion multi-écrans améliorée

## Limitations et compromis

### ⚠️ Applications X11 uniquement

Certaines apps n'existent qu'en X11. Solutions :
1. Trouver alternative Wayland
2. Installer XWayland (ajouter `xwayland` aux packages)
3. Utiliser version web/Flatpak

### ⚠️ Nautilus tire des dépendances GNOME

Mais **pas Cinnamon** et **compatible Wayland**.

Alternatives légères :
```bash
# TUI file managers (0 deps GUI)
sudo apt install nnn lf ranger

# Lancer depuis terminal
nnn
```

### ⚠️ Bluetooth en CLI uniquement

Sans blueman, utiliser :
```bash
# bluetoothctl (standard)
bluetoothctl
> scan on
> pair XX:XX:XX:XX:XX:XX
> connect XX:XX:XX:XX:XX:XX

# Ou compiler bluetui (TUI Rust)
git clone https://github.com/pythops/bluetui
cd bluetui
cargo build --release
sudo cp target/release/bluetui /usr/local/bin/
```

## Prochaines améliorations

### Walker (lanceur d'applications Omarchy)

Remplacera wofi. Plus puissant et Wayland-pur.

```bash
# Sera ajouté dans une future version
git clone https://github.com/abenz1267/walker
cd walker
go build
```

### SwayOSD compilation

Pour affichage visuel volume/brightness à l'écran.

Déjà dans le script de compilation (option 6).

## Comparaison avec Omarchy

| Composant | Omarchy (Arch) | Notre script (Debian) |
|-----------|----------------|----------------------|
| WM | Hyprland | Hyprland (Sid/compilé) |
| Fichiers | Nautilus | Nautilus ✅ |
| Réseau | iwd | iwd ✅ |
| Audio | PipeWire + pamixer | PipeWire + pamixer ✅ |
| Notifs | mako | mako ✅ |
| Launcher | walker | wofi (walker à venir) |
| Terminal | Alacritty | Alacritty ✅ |
| DM | SDDM | SDDM ✅ |
| Bluetooth | bluetui | CLI (bluetui à compiler) |

**Similarité : ~90%** - seuls walker et bluetui manquent.

## Commandes utiles

### Gestion WiFi (iwd)
```bash
iwctl station wlan0 connect "SSID"
iwctl station wlan0 disconnect
```

### Gestion audio (pamixer)
```bash
pamixer --set-volume 50
pamixer --get-volume
pamixer -t  # Toggle mute
```

### Gestion Bluetooth
```bash
bluetoothctl power on
bluetoothctl scan on
bluetoothctl pair XX:XX:XX:XX:XX:XX
bluetoothctl connect XX:XX:XX:XX:XX:XX
```

### Screenshots
```bash
# Zone sélectionnée
grim -g "$(slurp)" - | wl-copy

# Écran complet
grim - | wl-copy

# Sauvegarder
grim ~/Pictures/screenshot.png
```

## Ressources

- [Omarchy packages](https://github.com/basecamp/omarchy/blob/main/install/omarchy-base.packages)
- [iwd wiki](https://wiki.archlinux.org/title/Iwd)
- [Wayland apps list](https://arewewaylandyet.com/)
- [Hyprland wiki](https://wiki.hyprland.org/)
