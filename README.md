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

## Notes
- Ensure you have a reliable internet connection during script execution.
- These scripts are intended for advanced users familiar with Linux system administration.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

