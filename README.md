# Script Documentation

This repository contains two essential Bash scripts for setting up and configuring Debian-based systems. Below are detailed explanations for each script and their usage.

## Scripts

### `debian-install-fresh.sh`

This script sets up a fresh Debian installation with LUKS encryption, Btrfs subvolumes, and a minimal base system. It also handles disk partitioning, cryptsetup configuration, and initial system setup in a chroot environment.

#### Features:
- Detects available disks and allows the user to select one for installation.
- Partitions the selected disk into EFI, boot, and root partitions.
- Configures LUKS encryption for the root partition.
- Sets up Btrfs subvolumes for root, home, and snapshots.
- Installs a minimal Debian system using `debootstrap`.
- Generates an `fstab` file and configures essential services like cryptsetup, GRUB, and network management.

#### Usage:
1. Boot your computer using a Debian LiveCD in console mode.
2. Ensure you have an active internet connection.
3. Clone this repository
4. Run the script as root:
   ```bash
   sudo ./debian-install-fresh.sh
   ```

#### Interactive Steps:
1. Select the target disk for installation.
2. Confirm the destruction of existing data on the selected disk.
3. Follow prompts for setting up root and user passwords during the chroot phase.

#### Final Steps After Execution:
- Reboot into your new Debian system.

---

### `debian-install-packages.sh`

This script automates the installation of essential packages and tools on a fresh Debian system. It includes features like package checking, error handling, and configuration setup for tmux, Neovim, and more.

#### Features:
- Installs a comprehensive list of base packages (e.g., i3-wm, polybar, tmux, git, curl).
- Adds Debian repositories with non-free and contrib components.
- Installs Neovim and picom from source.
- Configures tmux with a Catppuccin theme and plugin manager.
- Installs Flatpak and the Zen browser.
- Enables essential system services (e.g., lightdm, NetworkManager).
- Provides an installation summary highlighting successes and failures.

#### Usage:
Run the script as root:
```bash
sudo ./debian-install-base.sh
```

#### Next Steps After Execution:
1. Reboot your system.
2. After booting, run `tmux` and press `prefix + I` to install tmux plugins.
3. Configure your desktop environment settings.

---

---

### `install-hyprland.sh`

This script automates the installation of Hyprland window manager and its ecosystem on Debian Testing/Sid. It offers two installation methods: from repositories or compilation from source.

#### Features:
- Detects Debian version
- Installs available packages from Debian Testing/Sid repos
- Optional compilation from source for latest versions
- Modular package organization (available, sid-only, source-only)
- Build dependencies management
- Comprehensive error handling and logging

#### Usage:
```bash
bash scripts/install-hyprland.sh
```

Choose between:
1. Install from Sid repositories (faster, recommended)
2. Compile from source (latest versions, takes longer)

For detailed information, see [HYPRLAND.md](HYPRLAND.md) and [PACKAGE_STATUS.md](PACKAGE_STATUS.md).

---

### `compile-hyprland-sources.sh`

Standalone script to compile Hyprland and related packages from their GitHub sources.

#### Features:
- Selective compilation (choose which packages to build)
- Automatic dependency resolution
- Support for CMake, Meson, Go, and Rust projects
- Installs to `/usr/local` with proper permissions

#### Usage:
```bash
bash scripts/compile-hyprland-sources.sh
```

Select packages to compile:
1. Hyprland (window manager + dependencies)
2. hyprlock (lock screen)
3. hypridle (idle daemon)
4. hyprpaper (wallpaper manager)
5. swww (animated wallpapers)
6. cliphist (clipboard manager)
7. All of the above

---

### `setup-hyprland-config.sh`

Creates a complete Hyprland configuration inspired by Omarchy's modular structure.

#### Features:
- Modular configuration files (envs, monitors, input, bindings, etc.)
- Automatic backup of existing configs
- Waybar configuration with sensible defaults
- Pre-configured keybindings and window rules
- Autostart configuration

#### Usage:
```bash
bash scripts/setup-hyprland-config.sh
```

Configuration files created in:
- `~/.config/hypr/` (Hyprland configs)
- `~/.config/waybar/` (status bar)

---

## Documentation

- **[HYPRLAND.md](HYPRLAND.md)** - Complete Hyprland installation and configuration guide
- **[PACKAGE_STATUS.md](PACKAGE_STATUS.md)** - Detailed package availability status for Debian

## Notes
- Ensure you have a reliable internet connection during script execution.
- These scripts are intended for advanced users familiar with Linux system administration.
- For Hyprland, Debian Testing (Forky) or Sid (Unstable) is required.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

