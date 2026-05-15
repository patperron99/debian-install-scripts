# TODO — Debian Sway Install Suite

Installation Debian opinionée, style Omarchy — Wayland-pur, APT only.
Dernière mise à jour : 2026-05-14

---

## État des scripts principaux

| Script | État |
|--------|------|
| `debian-install-fresh.sh` | ✅ LUKS + Btrfs + debootstrap + install.conf (non-interactif) |
| `scripts/install-sway.sh` | ✅ APT Debian Testing, zéro Sid requis |
| `scripts/setup-sway-config.sh` | ✅ Config modulaire complète |
| `scripts/theme-picker.sh` | ✅ Refactorisé — templates envsubst + fichiers theme |
| `scripts/verify-install.sh` | ✅ Diagnostic PASS/FAIL |

---

## En cours / À faire

### Scripts manquants

- [x] `scripts/setup-snapshots.sh` — Configure snapper + hooks APT pre/post + timers systemd
- [x] `scripts/setup-auto-updates.sh` — Timer systemd user pour vérification quotidienne (APT + Flatpak)
- [ ] `scripts/setup-multimonitor.sh` — Config interactive workspaces par moniteur via `kanshi`
- [ ] `scripts/fetch-wallpapers.sh` — Télécharge wallpapers curatés libres de droits par thème

### Améliorations en attente

- [x] `debian-install-fresh.sh` — Installation non-interactive via `install.conf` :
  - `install.conf.example` versionné, `install.conf` gitignored
  - Passwords collectés une seule fois en début de script, passés au chroot via fichier secrets (shredé après usage)
  - Locale/timezone/hostname/username non-interactifs dans `chroot_setup.sh`
  - `setup-sway-config.sh` skippable via `NONINTERACTIVE=1`

- [ ] Nerd Fonts — Remplacer `git clone` (5GB) par téléchargement ciblé `.tar.xz`
  - JetBrainsMono + FiraCode + Hack depuis GitHub releases
  - Installer dans `~/.local/share/fonts/` + `fc-cache -fv`

- [x] Waybar — module `custom/updates` : compte APT + Flatpak, clic → terminal upgrade
  - APT hook `81waybar-updates` signale Waybar après `apt update` / dpkg
  - Timer système `apt-refresh.timer` fait `apt-get update` quotidien (root)

- [x] Plymouth — configurer splash screen au boot + thème par défaut

- [x] Power menu — option "Screensaver" ajoutée (`powermenu.sh`, lié à `screensaver-launch.sh`)

- [x] Restauration snapshot au boot — grub-btrfs (menu GRUB) + `restore-snapshot` (swap subvolume @)

---

## Problèmes connus / Décisions

- Migration Hyprland → Sway complète (branch `sway`) — Debian Testing pur, zéro Sid
- `greetd` remplacé par `agetty` autologin (plus simple, moins de dépendances)
- `swww` absent d'APT — `swaybg` utilisé à la place (stable, Wayland-natif)
- `adwaita-qt` préféré à `kvantum` (moins de dépendances)
- Nerd Fonts : éviter `git clone` du repo entier (~5GB) — télécharger archives ciblées
- Slack : webapp Chromium (`--app=https://app.slack.com/client`), pas de tray icon possible sur Wayland

---

## Wishlist / Futur

- [ ] Script détection GPU (Intel/AMD/NVIDIA) → env vars au boot
- [ ] bluetui — TUI bluetooth (Rust, pas dans APT)
- [ ] Test XDG portals (screenshot + file picker)
- [ ] Revue permissions sandbox Flatpak
