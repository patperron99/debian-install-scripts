# Legacy Hyprland Support

This directory contains archived Hyprland-specific files from the Debian install suite.

**Status**: Hyprland support has been deprecated in favor of Sway (Wayland-pure, APT-only).

## Contents

- `postinstall-hyprland.sh` — Main interactive menu for Hyprland setup
- `scripts/install-hyprland.sh` — Package installation for Hyprland
- `scripts/install-extras-hyprland.sh` — Development tools for Hyprland
- `scripts/setup-hyprland-config.sh` — Configuration deployment for Hyprland
- `scripts/setup-hyprlock.sh` — Lock screen setup for Hyprland
- `HYPRLAND.md` — Hyprland documentation

## Why Archived?

1. **Sway is the primary compositor** — Stable in Debian APT (Testing)
2. **Hyprland requires Sid** — Unstable sources, frequent breakage
3. **Maintenance burden** — Duplicate scripts for two compositors

## Using Sway Instead

See the main `README.md` and `postinstall-sway.sh` for current setup instructions.

## Restoring Hyprland (if needed)

If you need Hyprland support:
```bash
cd docs/legacy
bash postinstall-hyprland.sh
```

Note: Hyprland packages may not be available in your Debian version.
