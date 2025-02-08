# Debian Post-Installation Setup Script

This Bash script automates the installation and configuration of essential packages and tools on a Debian-based system. It sets up repositories, installs necessary software, and configures the system for an optimal development environment.

## Features

- Adds Debian repositories for `non-free` and `contrib` packages.
- Installs a curated list of base packages (e.g., `i3-wm`, `rofi`, `git`, `python3-pip`).
- Sets up and installs dependencies for `picom` (with blur support) and `Neovim` from source.
- Configures `tmux` with plugins and a Catppuccin theme.
- Enables essential services (e.g., `NetworkManager`, `lightdm`, `bluetooth`).
- Installs the Zen browser via Flatpak.

## Prerequisites

- A Debian-based system.
- Root privileges to execute the script (`sudo` or `root` user).

## Usage

1. Clone the repository or save the script to your system.
2. Make the script executable:
   ```bash
   chmod +x setup.sh
   ```
3. Run the script as root:
   ```bash
   sudo ./setup.sh
   ```

## Configuration

- **Base Packages**: Modify the `BASE_PACKAGES` array in the script to add or remove packages.
- **Picom Dependencies**: Update the `PICOM_DEPS` array if additional dependencies are required.
- **Tmux Configuration**: Edit the `.tmux.conf` section in the script to customize settings.

## Installation Summary

- At the end of the script, a summary of successfully installed and failed packages will be displayed.
- Failed packages are saved to `/root/failed_packages.txt` for troubleshooting.

## Next Steps

1. Reboot your system:
   ```bash
   sudo reboot
   ```
2. After rebooting, start `tmux` and press `prefix + I` to install plugins.
3. Configure your desktop environment settings as needed.

## Notes

- The script installs `Neovim` and `picom` from source. Ensure that dependencies are correctly installed before running.
- For Flatpak installations, the script adds the Flathub repository if it doesn’t exist.

## Troubleshooting

If issues arise:
- Check the `FAILED_PACKAGES` array in the script output.
- Review `/root/failed_packages.txt` for details on failed installations.
- Ensure your system has an active internet connection and up-to-date package indices:
  ```bash
  sudo apt-get update
  ```

## License

This script is provided "as-is" without warranty. Modify and use it as needed for your environment.

