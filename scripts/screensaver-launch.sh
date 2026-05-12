#!/bin/bash
# screensaver-launch.sh — Launch TTE screensaver on all active Sway outputs

CONTENT_FILE="$HOME/.config/screensaver/content.txt"

# Calculate font size so the content fills ~65% of the output resolution.
# Falls back to default font size if no content file.
calc_font_size() {
    local output_name="$1"
    python3 -c "
import json, subprocess, os, sys

content_file = '$CONTENT_FILE'
output_name  = '$output_name'

try:
    outputs = json.loads(subprocess.check_output(['swaymsg', '-t', 'get_outputs']))
    output  = next((o for o in outputs if o['name'] == output_name), outputs[0])
    mode    = output.get('current_mode', {})
    scale   = output.get('scale', 1.0)
    w = mode.get('width',  1920) / scale
    h = mode.get('height', 1080) / scale
except Exception:
    w, h = 1920, 1080

try:
    with open(content_file) as f:
        lines = f.read().rstrip('\n').splitlines()
    cw = max(len(l) for l in lines) if lines else 0
    ch = len(lines)
    if cw == 0 or ch == 0:
        raise ValueError
except Exception:
    # No content file — use default font size
    print(0)
    sys.exit(0)

# JetBrains Mono metrics: at size S, char is approx S*0.60 px wide, S*1.55 px tall
size_w = w * 0.33 / cw / 0.60
size_h = h * 0.33 / ch / 1.55
print(max(8, int(min(size_w, size_h))))
"
}

swaymsg '[app_id="screensaver"] kill' 2>/dev/null
sleep 0.15

mapfile -t OUTPUTS < <(swaymsg -t get_outputs | \
    python3 -c "import sys,json; [print(o['name']) for o in json.load(sys.stdin) if o['active']]")

for output in "${OUTPUTS[@]}"; do
    swaymsg "focus output $output"
    sleep 0.15

    FONT_SIZE=$(calc_font_size "$output")

    if [[ "$FONT_SIZE" -gt 0 ]]; then
        foot -a screensaver --font="JetBrains Mono:size=${FONT_SIZE}" \
            bash ~/.local/bin/screensaver-tte.sh &
    else
        foot -a screensaver \
            bash ~/.local/bin/screensaver-tte.sh &
    fi

    sleep 0.5
    swaymsg '[app_id="screensaver"] focus, fullscreen enable' 2>/dev/null
done
