# Package Status — Debian Testing (Forky)

Status of packages for **Sway** installation.

Dernière mise à jour : Mai 2026

> **Migration Note:** Hyprland support has been archived to `docs/legacy/`. This document focuses on Sway packages available in Debian Testing (Forky).

---

## ✅ Core Sway Packages (Debian Testing — Forky)

| Package | Version | Notes |
|---------|---------|-------|
| sway | ✅ v1.8+ | Wayland compositor |
| swaybg | ✅ | Background setter |
| swayidle | ✅ | Idle manager |
| swaylock | ✅ | Lock screen |
| swaymsg | ✅ | IPC command |
| waybar | ✅ v0.12.0+ | Status bar |
| wofi | ✅ | App launcher |
| mako-notifier | ✅ | Notification daemon |
| xdg-desktop-portal-wlr | ✅ | XDG Portals (Wayland) |

---

## ✅ Audio & Bluetooth (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| pipewire | ✅ | Audio server |
| pipewire-pulse | ✅ | PulseAudio compatibility |
| pipewire-alsa | ✅ | ALSA compatibility |
| wireplumber | ✅ | Session manager |
| pulsemixer | ✅ | TUI audio mixer |
| pamixer | ✅ | CLI mixer |
| bluez | ✅ | Bluetooth stack |
| bluetui | ⚙️ | Python pip (TUI Bluetooth) |

---

## ✅ Screenshots & Recording (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| grim | ✅ | Screenshot tool |
| slurp | ✅ | Area selector |
| wf-recorder | ✅ | Screen recording |
| cliphist | ✅ | Clipboard manager |

---

## ✅ System Utilities (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| kanshi | ✅ | Multi-monitor profiles |
| brightnessctl | ✅ | Brightness control |
| playerctl | ✅ | Media player control |
| udiskie | ✅ | USB mounting |
| iwd | ✅ | WiFi daemon (replaces wpa_supplicant) |
| avahi-daemon | ✅ | mDNS/DNS-SD |
| power-profiles-daemon | ✅ | Power profile switching |

---

## ✅ Development Tools (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| git | ✅ | Version control |
| curl | ✅ | HTTP client |
| wget | ✅ | Download tool |
| fzf | ✅ | Fuzzy finder |
| fd-find | ✅ | find alternative |
| ripgrep | ✅ | grep alternative |
| jq | ✅ | JSON parser |
| shellcheck | ✅ | Bash linter |
| cmake | ✅ | Build system |
| meson | ✅ | Build system |
| ninja-build | ✅ | Build tool |

---

## ✅ Terminals (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| alacritty | ✅ | GPU-accelerated terminal |
| kitty | ✅ | GPU-accelerated terminal |
| foot | ✅ | Lightweight terminal |

---

## ✅ Editor & Shell (Debian Testing)

| Package | Source | Notes |
|---------|--------|-------|
| neovim | Testing (new) | Full-featured, latest |
| tmux | ✅ | Terminal multiplexer |
| bash | ✅ | Default shell |

---

## ✅ Fonts (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| fonts-noto | ✅ | System font (unicode) |
| fonts-noto-color-emoji | ✅ | Color emoji support |
| fonts-font-awesome | ✅ | Icon font |
| fonts-jetbrains-mono | ✅ | Monospace (installed locally) |
| fonts-firacode | ✅ | Monospace (installed locally) |

**Note:** Nerd Fonts (JetBrainsMono, FiraCode, Hack) are downloaded as `.tar.xz` archives from GitHub releases and installed to `~/.local/share/fonts/NerdFonts/` to avoid cloning the 5GB repo.

---

## ✅ Qt/GTK Support (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| qt5ct | ✅ | Qt5 theme configurator |
| qtwayland5 | ✅ | Qt5 Wayland support |
| qt6-wayland | ✅ | Qt6 Wayland support |
| adwaita-qt | ✅ | Qt5 Adwaita theme |

---

## ✅ Other (Debian Testing)

| Package | Version | Notes |
|---------|---------|-------|
| flatpak | ✅ | Sandboxed apps |
| fwupd | ✅ | Firmware updater |
| plymouth | ✅ | Boot splash screen |
| python3-pipx | ✅ | Python package installer |
| python3-pip | ✅ | pip (for bluetui, etc.) |

---

## ⚠️ Packages from Sid (Not Recommended)

For maximum stability, stay on Debian Testing (Forky). These packages may require Sid sources:

| Package | Reason | Alternative |
|---------|--------|-------------|
| hyprland | Removed from Forky | Use **Sway** (stable in Testing) |
| xdg-desktop-portal-hyprland | Hyprland-specific | Use xdg-desktop-portal-wlr |
| hyprlock | Hyprland-specific | Use swaylock or hyprlock (works with Sway too) |

---

## 🎯 Summary

✅ **All Sway essentials available in Debian Testing**

- **Wayland-pure:** Zero X11 dependencies
- **APT-only:** No compilation, no Sid sources required
- **Stable:** No breaking changes mid-install
- **Lightweight:** ~1.5GB disk footprint (vs. GNOME/KDE ~3GB+)

For latest package versions, run:
```bash
apt-cache policy <package-name>
```

---

## See Also

- [Sway Official](https://swaywm.org/)
- [Wayland Desktop Info](https://wayland.freedesktop.org/)
- [Debian Testing Packages](https://packages.debian.org/testing/)
