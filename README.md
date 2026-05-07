# Debian Install Scripts

Automation suite for fresh Debian installations with a Wayland-pure Hyprland desktop.

Targets **Debian Testing (Forky)** and **Sid (Unstable)**. All packages are installed via APT — no compilation required.

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
bash postinstall-hyprland.sh
```

The interactive menu lets you run everything at once or step by step:

```
  a) Install everything (recommended)
  ────────────────────────────────────
  1) Core + Hyprland packages
  2) Deploy configuration files
  3) Extras  (neovim, tmux, fonts, wlogout)
  4) Theme   (GTK, cursor, Neovim/LazyVim)
  5) Lock screen  (hyprlock + hypridle)
  6) Wallpapers
  7) Auto-update timer
  8) Multi-monitor layout
  ────────────────────────────────────
  9) Verify installation
```

Reboot when done — greetd/tuigreet lancera **Hyprland** automatiquement.

---

## Workflow

```
debian-install-fresh.sh
  └── postinstall-hyprland.sh               # Interactive menu
        ├── scripts/install-hyprland.sh     # Packages from APT (Forky + Sid)
        ├── scripts/setup-hyprland-config.sh# Deploy all configs
        ├── scripts/install-extras-hyprland.sh # Dev tools, fonts, TPM, Flatpak
        ├── scripts/setup-theme.sh          # GTK + cursor + Neovim
        ├── scripts/setup-hyprlock.sh       # Lock screen
        ├── scripts/fetch-wallpapers.sh     # Download wallpapers
        ├── scripts/setup-wallpaper.sh      # Select wallpaper
        ├── scripts/setup-auto-updates.sh   # Systemd update timer
        ├── scripts/setup-multimonitor.sh   # Monitor layout
        └── scripts/verify-install.sh       # Diagnostic
```

**Scripts re-runnable individually at any time:**

```
scripts/setup-wallpaper.sh       # Select wallpaper interactively
scripts/setup-theme.sh           # GTK / cursor / Qt / Neovim theme
scripts/setup-hyprlock.sh        # Lock screen timers
scripts/setup-updates.sh         # Interactive system updater
scripts/setup-auto-updates.sh    # Daily update check (systemd timer)
scripts/setup-multimonitor.sh    # Workspace-per-monitor layout
scripts/verify-install.sh        # PASS/FAIL diagnostic
```

**Helper scripts installed to `~/.local/bin/`:**

```
powermenu.sh      # SUPER+SHIFT+P — power menu (wlogout)
wallpaper-next.sh # SUPER+W       — cycle wallpaper
theme-picker.sh   # SUPER+SHIFT+T — live theme switcher (wofi)
check-updates.sh  # Waybar badge  — APT + Flatpak update count
```

---

## Configuration files deployed

`setup-hyprland-config.sh` copies all configs from `configs/` into `~/.config/`:

| Source | Destination | Description |
|---|---|---|
| `configs/hypr/` | `~/.config/hypr/` | Hyprland — modular conf files |
| `configs/waybar/` | `~/.config/waybar/` | Status bar |
| `configs/wofi/` | `~/.config/wofi/` | App launcher |
| `configs/wlogout/` | `~/.config/wlogout/` | Power menu |
| `configs/mako/` | `~/.config/mako/` | Notification daemon |
| `configs/kanshi/` | `~/.config/kanshi/` | Multi-monitor profiles |
| `configs/alacritty/` | `~/.config/alacritty/` | Terminal (+ themes) |
| `configs/kitty/` | `~/.config/kitty/` | Terminal (Nord theme) |
| `configs/tmux/` | `~/.config/tmux/` | Multiplexer (Nord + TPM) |
| `configs/bashrc/` | `~/.bashrc` | Shell (Nord prompt, aliases) |
| `configs/nvim/` | `~/.config/nvim/` | Neovim — LazyVim + Nord |

`setup-theme.sh` writes GTK/cursor/Qt settings dynamically based on your choices.

---

## Scripts

### `debian-install-fresh.sh`

Disk setup from a LiveCD. Prompts for target disk, sets up LUKS, Btrfs subvolumes, installs a minimal Debian base via debootstrap, configures GRUB, crypttab, and fstab.

```bash
sudo bash debian-install-fresh.sh
```

---

### `postinstall-hyprland.sh`

Interactive menu — single entry point after first boot. Choose `a` to install everything or `1–9` for individual steps. Re-running is safe; each step is idempotent.

```bash
bash postinstall-hyprland.sh
```

---

### `scripts/install-hyprland.sh`

Installs the full Hyprland ecosystem from APT. Automatically adds Sid sources if needed and pins them to prevent unintended upgrades.

**Forky:** waybar, wofi, mako-notifier, grim, slurp, kanshi, alacritty, greetd, tuigreet, wf-recorder, swaybg, and more.  
**Sid:** hyprland, xdg-desktop-portal-hyprland, hyprlock, hypridle, hyprpicker, swayosd, cliphist.

```bash
bash scripts/install-hyprland.sh
```

---

### `scripts/setup-hyprland-config.sh`

Deploys all configuration files from `configs/` to their destinations (see table above). Backs up existing files with a `.backup` extension before overwriting.

```bash
bash scripts/setup-hyprland-config.sh
```

---

### `scripts/install-extras-hyprland.sh`

Installs developer tools and sets up language runtimes:

- **Packages:** neovim, tmux, cmake, flatpak, ripgrep, fd-find, fastfetch, wlogout, and more
- **Nerd Fonts:** JetBrainsMono, FiraCode, Hack (downloaded from GitHub releases)
- **TPM:** Tmux Plugin Manager cloned to `~/.config/tmux/plugins/tpm`
- **Flatpak:** Flathub remote + Zen browser

```bash
bash scripts/install-extras-hyprland.sh
```

---

### `scripts/setup-theme.sh`

Configures GTK theme, icon theme, cursor, Qt5ct, and Neovim.

**GTK choices:** Arc-Dark, Arc, Numix-Dark, Adwaita  
**Cursor choices:** Bibata-Modern-Classic, Breeze, Adwaita  
**Icons:** Papirus-Dark  
**Neovim:** LazyVim base + Nord colorscheme (`configs/nvim/lua/plugins/colorscheme.lua`)

```bash
bash scripts/setup-theme.sh
```

---

### `scripts/setup-hyprlock.sh`

Deploys `hyprlock.conf` and `hypridle.conf` from `configs/hypr/`, then enables hypridle in `autostart.conf`.

**Idle timers:** dim at 5 min → lock at 10 min → display off at 15 min → suspend at 30 min.

```bash
bash scripts/setup-hyprlock.sh
```

---

### `scripts/setup-wallpaper.sh`

Interactive wallpaper picker. Lists images from `~/Pictures/Wallpapers/`, writes `~/.config/hypr/hyprpaper.conf`, and applies the change live if Hyprland is running.

```bash
bash scripts/setup-wallpaper.sh
```

---

### `scripts/setup-updates.sh`

System updater with Waybar integration.

- **Interactive mode:** `apt update` → list pending → prompt upgrade → detect reboot-required
- **`--check` mode:** emits Waybar JSON with APT + Flatpak update counts

```bash
bash scripts/setup-updates.sh           # Interactive
bash scripts/setup-updates.sh --check   # Waybar JSON
```

---

### `scripts/setup-auto-updates.sh`

Creates a systemd user timer that runs `check-updates.sh` daily and 5 min after boot. Results appear as a Waybar badge (green = up to date, orange = updates available).

```bash
bash scripts/setup-auto-updates.sh
```

---

### `scripts/setup-multimonitor.sh`

Detects connected monitors (via `hyprctl` or `/sys/class/drm`) and assigns workspaces: 1–3 on primary, 4–10 on secondary. Writes `monitors.conf` and a `kanshi` profile.

```bash
bash scripts/setup-multimonitor.sh
```

---

### `scripts/verify-install.sh`

Read-only diagnostic. Checks binaries, systemd services, config files, APT sources, and Wayland purity. Exits 0 if all required checks pass.

```bash
bash scripts/verify-install.sh
```

---

## Default Keybindings

| Shortcut | Action |
|---|---|
| `SUPER + Return` | Terminal (alacritty) |
| `SUPER + D` | App launcher (wofi) |
| `SUPER + E` | File manager (nautilus) |
| `SUPER + Q` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + L` | Lock screen (hyprlock) |
| `SUPER + W` | Cycle wallpaper |
| `SUPER + B` | Bluetooth manager (blueman) |
| `SUPER + C` | Clipboard history (cliphist + wofi) |
| `SUPER + SHIFT + P` | Power menu (wlogout) |
| `SUPER + SHIFT + T` | Theme picker (wofi) |
| `SUPER + SHIFT + A` | Audio control (pavucontrol) |
| `SUPER + SHIFT + C` | Color picker (hyprpicker) |
| `SUPER + SHIFT + R` | Screen recording toggle (wf-recorder) |
| `SUPER + 1–3` | Switch workspace (primary monitor) |
| `SUPER + 4–0` | Switch workspace (secondary monitor) |
| `Print` | Screenshot area → clipboard |
| `SUPER + Print` | Screenshot → `~/Pictures/Screenshots/` |

---

## Documentation

- **[HYPRLAND.md](HYPRLAND.md)** — Troubleshooting and post-install notes
- **[PACKAGE_STATUS.md](PACKAGE_STATUS.md)** — Package availability matrix for Debian Forky/Sid
- **[WAYLAND_PURE.md](WAYLAND_PURE.md)** — Wayland-only architecture decisions
- **[TODO.md](TODO.md)** — Planned improvements and known issues

---

## Notes

- Requires Debian Testing (Forky) or Sid — not compatible with Debian Stable
- All scripts must be run from the repository root directory
- Intended for users familiar with Linux system administration

## License

MIT License. See the LICENSE file for details.
