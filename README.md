# Debian Install Scripts — Sway Edition

Automation suite for fresh Debian installations with a Wayland-pure **Sway** desktop.

Targets **Debian Testing (Forky)** — all packages from APT, zero compilation required.

> For legacy Hyprland support, see `docs/legacy/README.md`

---

## Installation

### Step 1 — Boot from Debian Live USB (XFCE)

Connect to WiFi via NetworkManager, then:

```bash
apt install git
git clone https://github.com/patperron99/debian-install-scripts
cd debian-install-scripts
sudo bash configure-install.sh
```

`configure-install.sh` collects all settings interactively (disk, filesystem, LUKS, hostname, locale, WiFi copy, passwords) then launches `debian-install-fresh.sh` automatically. The install script handles disk partitioning, LUKS encryption, Btrfs subvolumes (`@`, `@home`, `@snapshots`), debootstrap, GRUB, crypttab, and fstab.

Reboot into the new system.

### Step 2 — First boot (minimal Debian console)

WiFi is active via iwd + NetworkManager (copied from live USB). Clone the repo and run the postinstall:

```bash
sudo apt install git
git clone https://github.com/patperron99/debian-install-scripts
cd debian-install-scripts
bash postinstall-sway.sh
```

Interactive menu — run everything at once or step by step:

```
  a) Install everything (recommended)
  ────────────────────────────────────
  1) Core + Sway packages
  2) Deploy configuration files
  3) Extras  (neovim, tmux, fonts, yazi, bluetui)
  4) Theme   (GTK, cursor, Neovim/LazyVim)
  5) Wallpapers
  6) Auto-update timer
  7) BTRFS snapshots + GRUB boot entries
  8) Plymouth boot splash screen
  9) Multi-monitor layout
  ────────────────────────────────────
  10) Verify installation
```

At the end of step 1, NetworkManager is removed and **iwd takes over WiFi standalone** (use `impala` as TUI). Reboot when done — autologin on TTY1, Sway starts automatically.

---

## Workflow

```
debian-install-fresh.sh
  └── postinstall-sway.sh                  # Interactive menu
        ├── scripts/install-sway.sh        # Step 1: Core Sway packages + remove NM
        ├── scripts/setup-sway-config.sh   # Step 2: Deploy configs
        ├── scripts/install-extras-sway.sh # Step 3: Dev tools, fonts, yazi, bluetui
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
powermenu.sh          Super+Escape   — power menu (reboot/suspend/logout/lock)
wallpaper-next.sh     Super+W        — cycle wallpaper
theme-picker.sh       Super+Shift+T  — live theme switcher
check-updates.sh      Waybar module  — APT update count
screensaver-launch.sh Super+Shift+L  — start terminal screensaver
```

---

## Configuration Files Deployed

`setup-sway-config.sh` copies all configs from `configs/` into `~/.config/`:

| Source | Destination | Description |
|--------|-------------|-------------|
| `configs/sway/` | `~/.config/sway/` | Sway — main config |
| `configs/waybar/` | `~/.config/waybar/` | Status bar |
| `configs/wofi/` | `~/.config/wofi/` | App launcher |
| `configs/mako/` | `~/.config/mako/` | Notification daemon |
| `configs/kanshi/` | `~/.config/kanshi/` | Multi-monitor profiles |
| `configs/kitty/` | `~/.config/kitty/` | Terminal (+ themes) |
| `configs/tmux/` | `~/.config/tmux/` | Multiplexer (Nord + TPM) |
| `configs/bashrc/` | `~/.bashrc` | Shell (Nord prompt, aliases) |
| `configs/nvim/` | `~/.config/nvim/` | Neovim — LazyVim + Nord |
| `configs/hypr/hyprlock.conf` | `~/.config/hypr/hyprlock.conf` | Lock screen |

`setup-theme.sh` writes GTK/cursor/Qt settings dynamically based on your choices.

---

## Key Features

✅ **Wayland-pure** — No X11, no GNOME/KDE bloat  
✅ **APT-only** — All packages from Debian Testing, zero compilation  
✅ **iwd standalone** — Lightweight WiFi daemon, managed via `impala` TUI  
✅ **Disk encryption** — Full LUKS + Btrfs setup  
✅ **Snapshots** — Automated Btrfs snapshots with GRUB boot menu  
✅ **TUI-first** — pulsemixer (audio), bluetui (Bluetooth), yazi (files), impala (WiFi)  
✅ **Modular** — Install step-by-step or all at once  
✅ **Idempotent** — Safe to re-run any script  

---

## Keyboard Shortcuts

### Applications

| Shortcut | Action |
|----------|--------|
| Super+Return | Terminal (kitty) |
| Super+D | App launcher (wofi) |
| Super+E | File manager (yazi) |
| Super+B | Browser (Zen) |
| Super+Shift+S | Slack |
| Super+Shift+A | Audio mixer (pulsemixer) |

### Window Management

| Shortcut | Action |
|----------|--------|
| Super+Q | Close window |
| Super+F | Fullscreen toggle |
| Super+V | Floating toggle |
| Super+J | Layout toggle (split/tabbed) |
| Super+Shift+E | Exit Sway |
| Super+Shift+C | Reload config |

### Focus & Move

| Shortcut | Action |
|----------|--------|
| Super+Arrow | Focus window in direction |
| Super+Shift+Arrow | Move window in direction |
| Super+- | Shrink window |
| Super+= | Grow window |

### Workspaces

| Shortcut | Action |
|----------|--------|
| Super+1–0 | Switch to workspace 1–10 |
| Super+Shift+1–0 | Move window to workspace 1–10 |
| Super+Scroll | Previous / next workspace |

### Scratchpad

| Shortcut | Action |
|----------|--------|
| Super+Shift+- | Send window to scratchpad |
| Super+Ctrl+- | Show scratchpad |

### Lock / Power

| Shortcut | Action |
|----------|--------|
| Super+L | Lock screen (hyprlock) |
| Super+Shift+L | Screensaver |
| Super+Escape | Power menu (shutdown/reboot/suspend/logout) |

### Clipboard & Screenshots

| Shortcut | Action |
|----------|--------|
| Super+C | Clipboard history picker |
| Super+P | Screenshot area → clipboard |
| Super+Shift+P | Screenshot fullscreen → clipboard |
| Super+Ctrl+P | Screenshot fullscreen → file |
| Super+Shift+R | Toggle screen recording (wf-recorder) |

### Wallpaper & Theme

| Shortcut | Action |
|----------|--------|
| Super+W | Cycle wallpaper |
| Super+Shift+T | Live theme switcher |

### Media & Brightness

| Shortcut | Action |
|----------|--------|
| XF86AudioRaiseVolume | Volume +5% |
| XF86AudioLowerVolume | Volume -5% |
| XF86AudioMute | Toggle mute |
| XF86AudioPlay | Play/pause |
| XF86AudioNext / Prev | Next / previous track |
| XF86MonBrightnessUp | Brightness +5% |
| XF86MonBrightnessDown | Brightness -5% |

---

## Scripts Reference

### `debian-install-fresh.sh`

Disk setup from a Live USB. Prompts for target disk, sets up LUKS, Btrfs subvolumes (`@`, `@home`, `@snapshots`), installs a minimal Debian base via debootstrap, configures GRUB, crypttab, and fstab. Optionally copies WiFi profiles from the live system.

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

Installs the full Sway ecosystem from APT Testing, then removes NetworkManager (iwd takes over standalone WiFi management).

**Packages:** sway, swaybg, swayidle, waybar, wofi, mako-notifier, grim, slurp, wf-recorder, kitty, pipewire, wireplumber, pulsemixer, kanshi, udiskie, brightnessctl, playerctl, bluez, hyprlock, chromium, and more.

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

Installs developer tools, TUI utilities, and fonts:

- **Packages:** neovim, tmux, ripgrep, fd-find, bat, zoxide, fastfetch, jq, shellcheck, fwupd, nvme-cli, smartmontools, and yazi preview deps
- **Build tools:** cmake, meson, ninja-build
- **Nerd Fonts:** JetBrainsMono, FiraCode, Hack (v3.2.1 from GitHub releases)
- **GitHub binaries:** bluetui, impala, yazi, superfile (spf), zen browser
- **TPM:** Tmux Plugin Manager cloned to `~/.config/tmux/plugins/tpm`
- **VPN:** pritunl-client (optional, latest .deb from GitHub)

```bash
bash scripts/install-extras-sway.sh
```

---

### `scripts/setup-theme.sh`

Configures GTK theme, icon theme, cursor, Qt5ct, and Neovim.

**GTK choices:** Arc-Dark, Arc, Adwaita  
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

Configures Btrfs snapshots with snapper, APT hooks, and systemd timers. Requires Btrfs filesystem.

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

## Troubleshooting

### No sound
```bash
pulsemixer        # TUI audio mixer  (Super+Shift+A)
pactl list short sinks
```

### Bluetooth issues
```bash
bluetui           # TUI Bluetooth manager
systemctl status bluetooth
```

### WiFi issues
```bash
impala            # TUI WiFi manager (iwd)
iwctl             # iwd interactive CLI
systemctl status iwd
```

### Monitor not detected
```bash
swaymsg -t get_outputs
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
