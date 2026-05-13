# TODO — Debian Sway Install Suite

Installation Debian opinionée, style Omarchy — Wayland-pur, APT only.
Dernière mise à jour : 2026-05-12

---

## État des scripts principaux

| Script | État |
|--------|------|
| `debian-install-fresh.sh` | ✅ LUKS + Btrfs + debootstrap |
| `scripts/install-sway.sh` | ✅ APT Debian Testing, zéro Sid requis |
| `scripts/setup-sway-config.sh` | ✅ Config modulaire complète |
| `scripts/theme-picker.sh` | ✅ Refactorisé — templates envsubst + fichiers theme |
| `scripts/verify-install.sh` | ✅ Diagnostic PASS/FAIL |

---

## En cours / À faire

### Scripts manquants

- [ ] `scripts/setup-snapshots.sh` — Configure snapper + hooks APT pre/post + timers systemd
- [ ] `scripts/setup-auto-updates.sh` — Timer systemd user pour vérification quotidienne (APT + Flatpak)
- [ ] `scripts/setup-multimonitor.sh` — Config interactive workspaces par moniteur via `kanshi`
- [ ] `scripts/fetch-wallpapers.sh` — Télécharge wallpapers curatés libres de droits par thème

### Améliorations en attente

- [ ] `debian-install-fresh.sh` — Premier boot automatisé :
  - Copier le repo dans `/mnt/opt/debian-install-scripts/`
  - Créer service systemd `first-boot-setup.service` (oneshot → postinstall)

- [ ] Nerd Fonts — Remplacer `git clone` (5GB) par téléchargement ciblé `.tar.xz`
  - JetBrainsMono + FiraCode + Hack depuis GitHub releases
  - Installer dans `~/.local/share/fonts/` + `fc-cache -fv`

- [ ] Waybar — module `custom/updates` : compte APT + Flatpak, clic → terminal upgrade
  - Bug : le statut ne se rafraîchit pas après une mise à jour (cache pas invalidé)

- [ ] Plymouth — configurer splash screen au boot + thème par défaut

- [ ] Power menu — ajouter l'option "Screensaver" (lock + screensaver via `screensaver-launch.sh`)

- [ ] Restauration snapshot au boot — menu GRUB ou script de boot pour rollback Btrfs/snapper

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
