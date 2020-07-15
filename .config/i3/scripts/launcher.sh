#!/bin/bash
# Run configure monitors script
$HOME/.config/i3/scripts/configure_monitors

# Run polybar
killall polybar
$HOME/.config/polybar/launch.sh &

# Set wallpaper
feh --bg-scale ~/.config/feh/wallpaper2.jpg &

# Exec network manager applet
killall nm-applet
nm-applet --no-agent &

# Exec bluetooth applet
killall blueman-applet
blueman-applet &

