# TODO — Debian Hyprland Install Suite

Installation Debian opinionée, style Omarchy — Wayland-pur, APT only.
Dernière mise à jour : 2026-04-29

---

## État des scripts principaux

| Script | État |
|--------|------|
| `debian-install-fresh.sh` | ✅ LUKS + Btrfs + debootstrap |
| `postinstall-hyprland.sh` | ✅ Orchestrateur CORE/BASE/Hyprland/Extras |
| `scripts/install-hyprland.sh` | ✅ APT Forky + Sid auto-add + pinning |
| `scripts/setup-hyprland-config.sh` | ✅ Config modulaire complète |
| `scripts/install-extras-hyprland.sh` | ✅ Fonctionnel (bug Nerd Fonts à corriger) |
| `scripts/setup-wallpaper.sh` | ✅ Sélection interactive swaybg |
| `scripts/setup-theme.sh` | ✅ GTK / cursor / Qt / Neovim |
| `scripts/setup-updates.sh` | ✅ Mode interactif + Waybar JSON |
| `scripts/setup-hyprlock.sh` | ✅ hyprlock + hypridle timers |
| `scripts/verify-install.sh` | ✅ Diagnostic PASS/FAIL |

---

## En cours / À créer

### Nouveaux scripts

- [ ] `scripts/powermenu.sh` — Menu wofi : lock/logout/suspend/reboot/shutdown
- [ ] `scripts/wallpaper-next.sh` — Cycle vers le prochain wallpaper (pour raccourci clavier)
- [ ] `scripts/theme-picker.sh` — Menu wofi pour changer thème Hyprland/GTK/Neovim en live
- [ ] `scripts/fetch-wallpapers.sh` — Télécharge 6-10 wallpapers curatés libres de droits
- [ ] `scripts/setup-snapshots.sh` — Configure snapper + hooks APT pre/post + timers systemd
- [ ] `scripts/setup-auto-updates.sh` — Timer systemd user pour vérification quotidienne (APT + Flatpak)
- [ ] `scripts/setup-multimonitor.sh` — Config interactive workspaces par moniteur (primaire:1-3, secondaire:4-10)

### Modifications scripts existants

- [ ] `scripts/setup-hyprland-config.sh` — Ajouter bindings :
  - `SUPER+W` → wallpaper-next.sh
  - `SUPER+SHIFT+T` → theme-picker.sh
  - `SUPER+SHIFT+P` → powermenu.sh
  - `SUPER+B` → blueman-manager
  - `SUPER+SHIFT+A` → pavucontrol
  - Waybar : ajouter module `bluetooth` + améliorer module `network` (iwd SSID)

- [ ] `scripts/install-extras-hyprland.sh` — Corriger Nerd Fonts :
  - Remplacer `git clone` (5GB) par téléchargement ciblé des archives `.tar.xz`
  - JetBrainsMono + FiraCode + Hack depuis GitHub releases
  - Installer dans `~/.local/share/fonts/` + `fc-cache -fv`

- [ ] `postinstall-hyprland.sh` — Ajouter prompts :
  - "Fetch default wallpapers?" → `fetch-wallpapers.sh`
  - "Configure BTRFS snapshots?" → `setup-snapshots.sh`

- [ ] `debian-install-fresh.sh` — Premier boot automatisé :
  - Copier le repo dans `/mnt/opt/debian-install-scripts/`
  - Créer service systemd `first-boot-setup.service` (oneshot → postinstall-hyprland.sh)

### Documentation

- [ ] `TODO.md` — Ce fichier (en cours ✅)
- [ ] `README.md` — Documenter les nouveaux scripts dans le workflow
- [ ] `HYPRLAND.md` — Documenter les nouveaux raccourcis clavier

---

## Détail des nouvelles fonctionnalités

### Power menu (`scripts/powermenu.sh`)
```
SUPER+SHIFT+P → wofi --dmenu → Lock | Logout | Suspend | Reboot | Shutdown
```
Installé dans `~/.local/bin/powermenu.sh` par `setup-hyprland-config.sh`.

### Wallpaper cycling (`scripts/wallpaper-next.sh`)
```
SUPER+W → cycle vers le prochain wallpaper dans ~/Pictures/Wallpapers/
         (boucle circulaire, appliqué live via swaybg)
```
Lit/écrit `~/.config/hypr/autostart.conf` pour persister la sélection.

### Theme picker (`scripts/theme-picker.sh`)
```
SUPER+SHIFT+T → wofi --dmenu → Catppuccin | Nord | Gruvbox | Tokyo Night
                               (appliqué live : borders Hyprland + GTK + Alacritty)
```
Thèmes prédéfinis avec valeurs border/gradient pour hyprland + settings.ini GTK.

### Snapshots BTRFS (snapper)
```
apt upgrade → snapper pre-snapshot → upgrade → snapper post-snapshot
```
- Retention : 7 quotidiens, 4 hebdomadaires, 3 mensuels
- Timers systemd : `snapper-timeline.timer` + `snapper-cleanup.timer`
- Nécessite partition racine en Btrfs (détecté automatiquement, skip sinon)

### Mises à jour automatiques + Flatpak
```
Timer systemd user (quotidien, 5min après boot) → check-updates.sh
check-updates.sh : APT count + Flatpak count → Waybar JSON
Clic Waybar → terminal interactif (apt upgrade + flatpak update)
```

### Multi-moniteur (workspaces par moniteur)
```
Moniteur principal  → workspaces 1, 2, 3
Moniteur secondaire → workspaces 4, 5, 6, 7, 8, 9, 10
```
Généré par `setup-multimonitor.sh` via `hyprctl monitors` + règles `workspace =` dans `monitors.conf`.

### Waybar amélioré
```
[workspaces | window]  [clock]  [updates | bluetooth | audio | network | battery | tray]
```
- `bluetooth` : icône BT + toggle, clic → `blueman-manager`
- `network` : SSID via `iwctl` ou IP ethernet
- `custom/updates` : compte APT + Flatpak, vert/orange selon état

---

## Problèmes connus / Décisions

- `swww` absent d'APT — `swaybg` utilisé à la place (stable, Wayland-natif)
- `kvantum` dispo dans Forky mais `adwaita-qt` préféré (moins de dépendances)
- `iwd` préféré à NetworkManager (zéro dépendances GNOME)
- `cliphist` et `swaybg` viennent de Sid (pinning APT à 100 — install explicite seulement)
- Nerd Fonts : éviter `git clone` du repo entier (~5GB) — télécharger archives ciblées

---

## Wishlist / Futur

- [ ] Thème tuigreet (couleurs, greeting personnalisé)
- [ ] Script de détection GPU (Intel/AMD/NVIDIA) → env vars dans `envs.conf`
- [ ] Test XDG portals (screenshot + file picker)
- [ ] Revue des permissions sandbox Flatpak
- [ ] Walker launcher (remplace wofi — Go, pas dans APT)
- [ ] bluetui TUI bluetooth (Rust, pas dans APT)
