#!/bin/bash
set -uo pipefail

# Source common functions for colors
source "$(dirname "$0")/common_functions.sh"

echo -e "${GREEN}=== Hyprland Configuration Setup ===${NC}"
echo "This script will create basic Hyprland configuration files"
echo "inspired by Omarchy's clean and modular structure"
echo ""

CONFIG_DIR="$HOME/.config/hypr"

# Ask user for confirmation
echo -e "${YELLOW}This will create configuration files in $CONFIG_DIR${NC}"
echo -e "${YELLOW}Existing files will be backed up with .backup extension${NC}"
echo -e "${YELLOW}Do you want to continue? (y/n)${NC}"
read -r confirm

while [[ ! "$confirm" =~ ^[YyNn]$ ]]; do
    echo -e "${YELLOW}Please enter y or n:${NC}"
    read -r confirm
done

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Backup existing configs
echo ""
echo "Backing up existing configuration files..."
for file in hyprland.conf monitors.conf input.conf bindings.conf looknfeel.conf autostart.conf; do
    if [ -f "$CONFIG_DIR/$file" ]; then
        cp "$CONFIG_DIR/$file" "$CONFIG_DIR/$file.backup"
        echo -e "${GREEN}Backed up: $file${NC}"
    fi
done

# Create main hyprland.conf
echo ""
echo "Creating main configuration file..."
cat > "$CONFIG_DIR/hyprland.conf" << 'EOF'
# Hyprland Configuration
# Based on Omarchy's modular structure
# Learn more: https://wiki.hyprland.org/Configuring/

# Source modular configuration files
source = ~/.config/hypr/envs.conf
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/input.conf
source = ~/.config/hypr/looknfeel.conf
source = ~/.config/hypr/bindings.conf
source = ~/.config/hypr/autostart.conf
source = ~/.config/hypr/windowrules.conf

# Add any additional personal configuration below
EOF

echo -e "${GREEN}Created: hyprland.conf${NC}"

# Create envs.conf
cat > "$CONFIG_DIR/envs.conf" << 'EOF'
# Environment Variables
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = QT_QPA_PLATFORM,wayland
env = GDK_BACKEND,wayland
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
EOF

echo -e "${GREEN}Created: envs.conf${NC}"

# Create monitors.conf
cat > "$CONFIG_DIR/monitors.conf" << 'EOF'
# Monitor Configuration
# https://wiki.hyprland.org/Configuring/Monitors/

# Example configurations:
# monitor = eDP-1, 1920x1080@60, 0x0, 1
# monitor = HDMI-A-1, 2560x1440@144, 1920x0, 1

# Auto-detect monitor (recommended to start)
monitor = , preferred, auto, 1
EOF

echo -e "${GREEN}Created: monitors.conf${NC}"

# Create input.conf
cat > "$CONFIG_DIR/input.conf" << 'EOF'
# Input Configuration
# https://wiki.hyprland.org/Configuring/Variables/#input

input {
    kb_layout = us
    # kb_variant =
    # kb_model =
    # kb_options =
    # kb_rules =

    follow_mouse = 1

    touchpad {
        natural_scroll = true
        disable_while_typing = true
        tap-to-click = true
        middle_button_emulation = false
    }

    sensitivity = 0 # -1.0 - 1.0, 0 means no modification
}

gestures {
    workspace_swipe = true
    workspace_swipe_fingers = 3
}
EOF

echo -e "${GREEN}Created: input.conf${NC}"

# Create looknfeel.conf
cat > "$CONFIG_DIR/looknfeel.conf" << 'EOF'
# Look and Feel Configuration
# https://wiki.hyprland.org/Configuring/Variables/

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    layout = dwindle

    allow_tearing = false
}

decoration {
    rounding = 8

    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.1696
    }

    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

animations {
    enabled = true

    bezier = myBezier, 0.05, 0.9, 0.1, 1.05

    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_status = master
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}
EOF

echo -e "${GREEN}Created: looknfeel.conf${NC}"

# Create bindings.conf
cat > "$CONFIG_DIR/bindings.conf" << 'EOF'
# Keybindings Configuration
# https://wiki.hyprland.org/Configuring/Binds/

$mainMod = SUPER

# Application shortcuts
bind = $mainMod, Return, exec, alacritty
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, E, exit,
bind = $mainMod, E, exec, nautilus
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle
bind = $mainMod, F, fullscreen,

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Move focus with mainMod + vim keys
bind = $mainMod, h, movefocus, l
bind = $mainMod, l, movefocus, r
bind = $mainMod, k, movefocus, u
bind = $mainMod, j, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Media keys (using pamixer for Wayland-native control)
binde = , XF86AudioRaiseVolume, exec, pamixer -i 5
binde = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

# Brightness keys
binde = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
binde = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

# Screenshot (Wayland-native)
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy
bind = $mainMod, Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Lock screen (hyprlock if available, otherwise swaylock)
bind = $mainMod, L, exec, hyprlock || swaylock

# Color picker (if hyprpicker is installed)
bind = $mainMod SHIFT, C, exec, hyprpicker -a
EOF

echo -e "${GREEN}Created: bindings.conf${NC}"

# Create autostart.conf
cat > "$CONFIG_DIR/autostart.conf" << 'EOF'
# Autostart Configuration
# Applications to launch at startup

# Wallpaper
exec-once = swaybg -i ~/Pictures/wallpaper.png -m fill

# Status bar
exec-once = waybar

# Notification daemon
exec-once = mako

# Polkit agent (GNOME version for Wayland)
exec-once = /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1

# SwayOSD (volume/brightness OSD) - if compiled
exec-once = swayosd-server

# Idle management (if hypridle is installed)
# exec-once = hypridle

# Night light (if hyprsunset is installed)
# exec-once = hyprsunset

# Clipboard manager
exec-once = wl-paste --type text --watch wl-copy
exec-once = wl-paste --type image --watch wl-copy
EOF

echo -e "${GREEN}Created: autostart.conf${NC}"

# Create windowrules.conf
cat > "$CONFIG_DIR/windowrules.conf" << 'EOF'
# Window Rules
# https://wiki.hyprland.org/Configuring/Window-Rules/

# Example window rules
# windowrule = float, ^(pavucontrol)$
# windowrule = workspace 2, ^(firefox)$

# Float certain windows by default
windowrule = float, ^(org.gnome.Calculator)$
windowrule = float, ^(gnome-disk-utility)$

# Opacity rules
windowrulev2 = opacity 0.90 0.90, class:^(Alacritty)$
windowrulev2 = opacity 0.95 0.95, class:^(org.gnome.Nautilus)$
EOF

echo -e "${GREEN}Created: windowrules.conf${NC}"

# Create basic waybar config
echo ""
echo "Creating Waybar configuration..."
mkdir -p ~/.config/waybar

cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,

    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],

    "hyprland/workspaces": {
        "disable-scroll": false,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "1",
            "2": "2",
            "3": "3",
            "4": "4",
            "5": "5",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },

    "hyprland/window": {
        "format": "{}",
        "max-length": 50
    },

    "clock": {
        "format": "{:%H:%M | %a %d %b}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-icons": ["", "", "", "", ""]
    },

    "network": {
        "format-wifi": "{essid} ",
        "format-ethernet": "{ipaddr} ",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}/{cidr}"
    },

    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pamixer -t",
        "on-scroll-up": "pamixer -i 5",
        "on-scroll-down": "pamixer -d 5"
    },

    "tray": {
        "spacing": 10
    }
}
EOF

echo -e "${GREEN}Created: waybar/config${NC}"

cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.9);
    color: #ffffff;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: #ffffff;
}

#workspaces button.active {
    background-color: rgba(100, 114, 125, 0.4);
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#clock,
#battery,
#network,
#pulseaudio,
#tray {
    padding: 0 10px;
    margin: 0 3px;
}

#battery.charging {
    color: #26a65b;
}

#battery.warning:not(.charging) {
    color: #f39c12;
}

#battery.critical:not(.charging) {
    color: #eb4d4b;
}
EOF

echo -e "${GREEN}Created: waybar/style.css${NC}"

echo ""
echo -e "${GREEN}=== Configuration Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Configuration files created:${NC}"
echo "  - ~/.config/hypr/hyprland.conf (main config)"
echo "  - ~/.config/hypr/envs.conf (environment variables)"
echo "  - ~/.config/hypr/monitors.conf (display configuration)"
echo "  - ~/.config/hypr/input.conf (keyboard/mouse settings)"
echo "  - ~/.config/hypr/looknfeel.conf (appearance)"
echo "  - ~/.config/hypr/bindings.conf (keybindings)"
echo "  - ~/.config/hypr/autostart.conf (startup applications)"
echo "  - ~/.config/hypr/windowrules.conf (window rules)"
echo "  - ~/.config/waybar/config (waybar configuration)"
echo "  - ~/.config/waybar/style.css (waybar styling)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and customize the configuration files to your liking"
echo "2. Add a wallpaper image to ~/Pictures/wallpaper.png"
echo "3. Logout and select 'Hyprland' from your display manager"
echo "4. Press SUPER+D to launch applications"
echo "5. Press SUPER+Q to close windows"
echo ""
echo -e "${GREEN}Key shortcuts:${NC}"
echo "  SUPER + Return    : Open terminal"
echo "  SUPER + D         : Application launcher"
echo "  SUPER + E         : File manager"
echo "  SUPER + Q         : Close window"
echo "  SUPER + F         : Fullscreen"
echo "  SUPER + L         : Lock screen"
echo "  SUPER + 1-9       : Switch workspace"
echo "  Print             : Screenshot (area)"
echo ""
