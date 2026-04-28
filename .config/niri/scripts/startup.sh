#!/usr/bin/env bash

# Niri startup script
# Sets up applications on principal (HDMI-A-1) and side (DP-2) monitors

set -e

# Wait for niri to be fully initialized
sleep 0.2

# Clipboard history via cliphist (picker bound to Mod+Ctrl+V).
# wl-clip-persist intentionally not used: it races niri's screenshot data
# source and clobbers the image clipboard with stale text content.
pgrep -f "wl-paste.*cliphist store" >/dev/null || {
    wl-paste --type text  --watch cliphist store &
    wl-paste --type image --watch cliphist store &
}

# Principal monitor (HDMI-A-1) setup
echo "Setting up principal monitor (HDMI-A-1)..."

# Focus principal monitor
niri msg action focus-monitor HDMI-A-1

# Ensure we're on workspace 1
niri msg action focus-workspace 1

# Launch Google Chrome
google-chrome-stable &
sleep 0.2

# Switch to workspace 2
niri msg action focus-workspace 2

# Launch Alacritty terminal (simulating Mod+Enter)
alacritty &
sleep 0.1

# Side monitor (DP-2) setup
echo "Setting up side monitor (DP-2)..."

# Focus side monitor
niri msg action focus-monitor DP-2

# Ensure we're on workspace 1
niri msg action focus-workspace 1

# Launch Slack
slack &
sleep 0.2

# Switch to workspace 2
niri msg action focus-workspace 2

# Launch Firefox
firefox &
sleep 0.1

# Return focus to principal monitor
niri msg action focus-monitor HDMI-A-1

echo "Niri startup complete!"
