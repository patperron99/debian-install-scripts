#!/bin/bash
is_mode_exist=$(xrandr | grep "1920x1080R")
if [ -z "$is_mode_exist" ]; then
    xrandr --newmode "1920x1080R"  138.50  1920 1968 2000 2080  1080 1083 1088 1111 +hsync -vsync
    xrandr --addmode DP-3 1920x1080R
fi

xrandr --output DP-3 --mode 1920x1080R
