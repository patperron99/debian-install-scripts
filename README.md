# Debian Install Scripts — Sway Edition

Automation suite for fresh Debian installations with a Wayland-pure **Sway** desktop.

Targets **Debian Testing (Forky)** — all packages from APT, zero compilation required.

> **Note:** For legacy Hyprland support, see `docs/legacy/README.md`

---

## Installation

### Step 1 — Boot from Debian LiveCD

```bash
apt install git
git clone https://github.com/patperron99/debian-install-scripts
cd debian-install-scripts
sudo bash debian-install-fresh.sh
# Reboot into the new system
```

`debian-install-fresh.sh` handles disk setup: LUKS encryption, Btrfs subvolumes (`@`, `@home`, `@snapshots`), debootstrap, GRUB, crypttab, and fstab.

### Step 2 — First boot (minimal Debian console)

```bash
sudo apt install git
git clone https://github.com/patperron99/debian-install-scripts
cd debian-install-scripts
bash postinstall-sway.sh
```

The interactive menu lets you run everything at once or step by step:

```
  a) Install everything (recommended)
  ────────────────────────────────────
  1) Core + Sway packages
  2) Deploy configuration files
  3) Extras  (neovim, tmux, fonts, bluetui)
  4) Theme   (GTK, cursor, Neovim/LazyVim)
  5) Wallpapers
  6) Auto-update timer
  7) BTRFS snapshots + GRUB boot entries
  8) Plymouth boot splash screen
  9) Multi-monitor layout
  ────────────────────────────────────
  10) Verify installation
```

Reboot when done — autologin on TTY1, **Sway** starts automatically.

---

## Workflow

```
debian-install-fresh.sh
  └── postinstall-sway.sh                 # Interactive menu
        ├── scripts/install-sway.sh       # Step 1: Core Sway packages
        ├── scripts/setup-sway-config.sh  # Step 2: Deploy configs
        ├── scripts/install-extras-sway.sh # Step 3: Dev tools, fonts, bluetui
        ├── scripts/setup-theme.sh         # Step 4: GTK + cursor + Neovim
        ├── scripts/fetch-wallpapers.sh    # Step 5: Download wallpapers
        ├── scripts/setup-auto-updates.sh  # Step 6: APT timers + Waybar
        ├── scripts/setup-snapshots.sh     # Step 7a: Btrfs snapshots
        ├── scripts/setup-snapshot-boot.sh # Step 7b: GRUB recovery menu
        ├── scripts/setup-plymouth.sh      # Step 8: Boot splash screen
        ├── scripts/setup-multimonitor.sh  # Step 9: Kanshi + workspaces
        └── scripts/verify-install.sh      # Step 10: Diagnostic checks
```

**Scripts re-runnable individually at any time:**

```
scripts/setup-wallpaper.sh       # Select wallpaper interactively
scripts/setup-theme.sh           # GTK / cursor / Qt / Neovim theme
scripts/setup-auto-updates.sh    # Daily APT update check (systemd timer)
scripts/setup-snapshots.sh       # Btrfs snapper configuration
scripts/setup-multimonitor.sh    # Workspace-per-monitor layout
scripts/verify-install.sh        # PASS/FAIL diagnostic
```

**Helper scripts installed to `~/.local/bin/`:**

```
powermenu.sh       # Super key       — power menu (reboot/suspend/logout)
wallpaper-next.sh  # SUPER+W         — cycle wallpaper
screensaver-launch.sh # SUPER+S       — start terminal screensaver
theme-picker.sh    # SUPER+T         — live theme switcher
check-updates.sh   # Waybar module   — APT + Flatpak update count
```

---

## Configuration Files Deployed

`setup-sway-config.sh` copies all configs from `configs/` into `~/.config/`:

| Source | Destination | Description |
|---|---|---|
| `configs/sway/` | `~/.config/sway/` | Sway — main config |
| `configs/waybar/` | `~/.config/waybar/` | Status bar |
| `configs/wofi/` | `~/.config/wofi/` | App launcher |
| `configs/mako/` | `~/.config/mako/` | Notification daemon |
| `configs/kanshi/` | `~/.config/kanshi/` | Multi-monitor profiles |
| `configs/alacritty/` | `~/.config/alacritty/` | Terminal (+ themes) |
| `configs/tmux/` | `~/.config/tmux/` | Multiplexer (Nord + TPM) |
| `configs/bashrc/` | `~/.bashrc` | Shell (Nord prompt, aliases) |
| `configs/nvim/` | `~/.config/nvim/` | Neovim — LazyVim + Nord |
| `configs/hypr/hyprlock.conf` | `~/.config/hypr/hyprlock.conf` | Lock screen |

`setup-theme.sh` writes GTK/cursor/Qt settings dynamically based on your choices.

---

## Key Features

✅ **Wayland-pure** — No X11, no GNOME/KDE bloat  
✅ **APT-only** — All packages from Debian Testing, zero compilation  
✅ **Disk encryption** — Full LUKS + Btrfs setup  
✅ **Snapshots** — Automated Btrfs snapshots with GRUB boot menu  
✅ **TUI-first** — Pulsemixer (audio), bluetui (Bluetooth), lf (files)  
✅ **Modular** — Install step-by-step or all at once  
✅ **Idempotent** — Safe to re-run any script  

---

## Scripts Reference

### `debian-install-fresh.sh`

Disk setup from a LiveCD. Prompts for target disk, sets up LUKS, Btrfs subvolumes, installs a minimal Debian base via debootstrap, configures GRUB, crypttab, and fstab.

```bash
sudo bash debian-install-fresh.sh
```

---

### `postinstall-sway.sh`

Interactive menu — single entry point after first boot. Choose `a` to install everything or `1–10` for individual steps. Re-running is safe; each step is idempotent.

```bash
bash postinstall-sway.sh
```

---

### `scripts/install-sway.sh`

Installs the full Sway ecosystem from APT Testing.

**Packages:** sway, swaybg, swayidle, waybar, wofi, mako-notifier, grim, slurp, wf-recorder, alacritty, pipewire, wireplumber, pulsemixer, kanshi, udiskie, brightnessctl, playerctl, iwd, bluez, and more.

```bash
bash scripts/install-sway.sh
```

---

### `scripts/setup-sway-config.sh`

Deploys all configuration files from `configs/` to their destinations. Backs up existing files with a `.backup` extension before overwriting.

```bash
bash scripts/setup-sway-config.sh
```

---

### `scripts/install-extras-sway.sh`

Installs developer tools and sets up language runtimes:

- **Packages:** neovim, tmux, cmake, ripgrep, fd-find, fastfetch, jq, shellcheck, and more
- **Nerd Fonts:** JetBrainsMono, FiraCode, Hack (v3.2.1 from GitHub releases)
- **bluetui:** Python TUI Bluetooth manager (via pip)
- **TPM:** Tmux Plugin Manager cloned to `~/.config/tmux/plugins/tpm`

```bash
bash scripts/install-extras-sway.sh
```

---

### `scripts/setup-theme.sh`

Configures GTK theme, icon theme, cursor, Qt5ct, and Neovim.

**GTK choices:** Arc-Dark, Arc, Numix-Dark, Adwaita  
**Cursor choices:** Bibata-Modern-Classic, Breeze, Adwaita  
**Icons:** Papirus-Dark  
**Neovim:** LazyVim base + Nord colorscheme

```bash
bash scripts/setup-theme.sh
```

---

### `scripts/setup-auto-updates.sh`

Creates APT hooks and systemd timers for automatic update checks:

- **System timer:** Daily `apt-get update` (root)
- **APT hook:** Signals Waybar immediately on package changes
- **User timer:** Periodic Waybar refresh (5 min after boot, then hourly)

Results appear as a Waybar badge (green = up to date, orange = updates available).

```bash
bash scripts/setup-auto-updates.sh
```

---

### `scripts/setup-snapshots.sh`

Configures Btrfs snapshots with snapper, APT hooks, and systemd timers. Requires Btrfs filesystem (created by `debian-install-fresh.sh`).

```bash
bash scripts/setup-snapshots.sh
```

---

### `scripts/setup-snapshot-boot.sh`

Sets up GRUB menu with grub-btrfs to boot from snapshots, plus `restore-snapshot` script for interactive snapshot rollback.

```bash
bash scripts/setup-snapshot-boot.sh
```

---

### `scripts/setup-plymouth.sh`

Configures Plymouth boot splash screen. Interactive theme selection from available themes.

```bash
bash scripts/setup-plymouth.sh
```

---

### `scripts/setup-multimonitor.sh`

Detects connected monitors (via `swaymsg`) and assigns workspaces: 1–5 on primary, 6–10 on secondary. Writes `workspaces.conf` and kanshi profiles.

```bash
bash scripts/setup-multimonitor.sh
```

---

### `scripts/fetch-wallpapers.sh`

Downloads curated free wallpapers from Unsplash to `~/Pictures/Wallpapers/` with theme-specific variants.

```bash
bash scripts/fetch-wallpapers.sh
```

---

### `scripts/verify-install.sh`

Read-only diagnostic. Checks binaries, systemd services, config files, and Wayland purity. Exits 0 if all required checks pass.

```bash
bash scripts/verify-install.sh
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Super | Power menu (wlogout) |
| Super + W | Cycle wallpaper |
| Super + S | Terminal screensaver |
| Super + T | Live theme switcher |
| Super + 1–10 | Switch workspace |
| Super + Shift + 1–10 | Move window to workspace |

---

## Troubleshooting

### No sound
```bash
pulsemixer   # TUI audio mixer
pactl list short sinks
```

### Bluetooth issues
```bash
bluetui      # TUI Bluetooth manager
systemctl status bluetooth
```

### Monitor not detected
```bash
swaymsg -t get_outputs   # List monitors
bash scripts/setup-multimonitor.sh
```

### System updates failing
```bash
sudo apt update
sudo apt full-upgrade
```

---

## Legacy Support

For Hyprland (deprecated), see `docs/legacy/README.md`.

---

## License

MIT
