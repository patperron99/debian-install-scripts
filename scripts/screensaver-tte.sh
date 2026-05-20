#!/bin/bash
# screensaver-tte.sh — TTE animation loop, launched inside kitty by screensaver-launch.sh

export PATH="$HOME/.local/bin:$PATH"

if ! command -v tte &>/dev/null; then
    echo "terminaltexteffects not found"
    echo "Run: pip install --user --break-system-packages terminaltexteffects"
    sleep 5
    exit 1
fi

SELF=$$
OLD_TTY=$(stty -g 2>/dev/null)
TTE_PID=""
WATCH_PID=""

cleanup() {
    kill "$TTE_PID"   2>/dev/null
    kill "$WATCH_PID" 2>/dev/null
    stty "$OLD_TTY"   2>/dev/null
    exit 0
}

# Keypress, Ctrl-C, or terminal hangup → lock before exiting
lock_and_cleanup() {
    kill "$TTE_PID"   2>/dev/null
    kill "$WATCH_PID" 2>/dev/null
    stty "$OLD_TTY"   2>/dev/null
    swaymsg exec -- hyprlock
    exit 0
}

trap lock_and_cleanup USR1 INT
trap cleanup          TERM HUP

# Raw mode so any key is detected immediately (no Enter needed)
stty -echo -icanon min 1 time 0 2>/dev/null

CONTENT_FILE="$HOME/.config/screensaver/content.txt"

gen_content() {
    if [[ -f "$CONTENT_FILE" ]]; then
        cat "$CONTENT_FILE"
    else
        python3 -c "
import os, random, string
try:
    with open('/dev/tty') as tty:
        sz = os.get_terminal_size(tty.fileno())
    cols, rows = sz.columns, sz.lines
except Exception:
    cols, rows = 80, 24
chars = string.ascii_letters + string.digits + '@#%&*+=~'
print('\n'.join(''.join(random.choices(chars, k=cols)) for _ in range(rows - 1)))
"
    fi
}

while true; do
    # Key watcher: any keypress → USR1 → cleanup
    ( IFS= read -r -s -n1 _ </dev/tty 2>/dev/null; kill -USR1 "$SELF" 2>/dev/null ) &
    WATCH_PID=$!

    gen_content | tte --random-effect --canvas-width 0 --canvas-height 0 --anchor-canvas c --anchor-text c 2>/dev/null &
    TTE_PID=$!

    wait "$TTE_PID"

    # TTE finished naturally — kill watcher and loop
    kill "$WATCH_PID" 2>/dev/null
    wait "$WATCH_PID" 2>/dev/null
done
