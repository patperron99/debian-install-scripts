# TODO — Debian Sway Install Suite

Installation Debian opinionée, style Omarchy — Wayland-pur, APT only.
Dernière mise à jour : 2026-05-22

---

## État des scripts principaux

| Script | État |
|--------|------|
| `debian-install-fresh.sh` | ✅ LUKS + Btrfs + debootstrap + install.conf (non-interactif) |
| `scripts/install-sway.sh` | ✅ APT Debian Testing, zéro Sid requis — inclut plymouth |
| `scripts/chroot-postinstall.sh` | ✅ 8 étapes complètes — APT hook + auto-updates + Plymouth |
| `scripts/setup-sway-config.sh` | ✅ Config modulaire complète |
| `scripts/theme-picker.sh` | ✅ Refactorisé — templates envsubst + fichiers theme |
| `scripts/verify-install.sh` | ✅ Diagnostic PASS/FAIL |

---

## En cours / À faire

### Bugs connus

- [x] `postinstall-sway.sh` — numérotation corrigée "X/9", message "Debian Stable" → "Debian Testing"
- [x] `install-sway.sh` + `install-extras-sway.sh` — doublon Zen browser supprimé de install-sway.sh
- [x] `screensaver-launch.sh` — remplacé `foot` par `kitty --class screensaver`
- [x] `chroot-postinstall.sh` — auto-updates et Plymouth absents du flux d'install automatisé
- [x] `setup-auto-updates.sh` — waybar-signal-updates : stdout non redirigé (`>/dev/null 2>&1`), doublon `check-updates.sh` supprimé

### Wishlist / Futur

- [ ] Script détection GPU (Intel/AMD/NVIDIA) → env vars au boot
- [ ] Test XDG portals (screenshot + file picker)
- [ ] Revue permissions sandbox Flatpak

---

## Complété

### Scripts

- [x] `scripts/setup-snapshots.sh` — Configure snapper + hooks APT pre/post + timers systemd
- [x] `scripts/setup-auto-updates.sh` — Timer systemd user pour vérification quotidienne (APT + Flatpak)
- [x] `scripts/setup-multimonitor.sh` — Config interactive workspaces par moniteur via `kanshi`
- [x] `scripts/fetch-wallpapers.sh` — Télécharge wallpapers curatés libres de droits par thème
- [x] `scripts/setup-plymouth.sh` — Splash screen boot + thème interactif
- [x] `scripts/setup-snapshot-boot.sh` — Menu GRUB snapshots + `restore-snapshot`
- [x] `scripts/fix-apt-hooks.sh` — Correctif APT hooks pour systèmes existants (APT 3.0)

### Fonctionnalités

- [x] `debian-install-fresh.sh` — Installation non-interactive via `install.conf`
- [x] Nerd Fonts — Téléchargement ciblé `.tar.xz` (JetBrainsMono, FiraCode, Hack v3.2.1)
- [x] Waybar `custom/updates` — Compte APT + Flatpak, clic → terminal upgrade
- [x] Power menu — Option "Screensaver" (`powermenu.sh` + `screensaver-launch.sh`)
- [x] Restauration snapshot au boot — Menu GRUB + swap subvolume `@`
- [x] Terminal — Alacritty remplacé par Kitty (5 thèmes: gruvbox, nord, catppuccin-mocha, tokyo-night, rose-pine)
- [x] Slack webapp — Chromium + profil dédié `~/.config/chromium-slack` + icône + `.desktop`
- [x] `configs/hypr/hyprlock.conf` — Ajout du fichier manquant (fix critique setup-sway-config.sh)
- [x] APT hooks — Fix exit codes pour APT 3.0 (`exit 0` explicite, `Post-Invoke-Success` → `Post-Invoke`)
- [x] Vestiges Hyprland — `WAYLAND_PURE.md` archivé dans `docs/legacy/`, `setup-updates.sh` supprimé, commentaire `kanshi/config` corrigé
- [x] Bluetooth — `bluetui` binaire GitHub (musl statique, x86_64/aarch64) remplace blueman + pip inexistant ; vérification de version dans `check-updates.sh`
- [x] Audio — `pulsemixer` TUI remplace `pavucontrol` (non installé) sur le clic waybar ; fenêtre flottante via `app_id="pulsemixer"`

---

## Décisions

- Migration Hyprland → Sway complète (branch `sway`) — Debian Testing pur, zéro Sid
- `greetd` remplacé par `agetty` autologin (plus simple, moins de dépendances)
- `swww` absent d'APT — `swaybg` utilisé à la place (stable, Wayland-natif)
- `adwaita-qt` préféré à `kvantum` (moins de dépendances)
- Nerd Fonts : télécharger archives ciblées (éviter `git clone` du repo entier ~5GB)
- Slack : webapp Chromium (`--app=https://app.slack.com/client`), pas de tray icon possible sur Wayland
- bluetui : binaire musl statique depuis GitHub releases (pythops/bluetui) — pip inexistant, cargo évité (trop lourd)
