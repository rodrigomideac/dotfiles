#!/bin/bash
# Toggle Claude window - show/hide scratchpad-style behavior
#
# OVERVIEW:
# This script provides a dropdown/scratchpad-style toggle for the Claude web app.
# It launches Claude in a Chrome app window and allows you to show/hide it across
# workspaces using a keyboard shortcut.
#
# STATE MANAGEMENT:
# Uses two temporary files to track window state:
#   - ON:  Window is visible on current workspace
#   - OFF: Window is hidden (moved to workspace 99)
#   - Neither: Process is running but state is unknown (triggers restart)
#
# BEHAVIOR:
# 1. If no process running: Launch Chrome app and mark as ON
# 2. If process running with no state files: Kill and restart (clean state)
# 3. If state is ON: Hide window (move to workspace 99) and mark OFF
# 4. If state is OFF: Show window (move to current monitor/workspace) and mark ON
#
# WINDOW FOCUSING:
# The Chrome app window is in the floating layout. After moving it to the current
# workspace, we call switch-focus-between-floating-and-tiling to ensure it receives
# focus. This is necessary because niri's default focus may remain on tiled windows.
#
# REQUIREMENTS:
# - niri window manager with IPC enabled
# - google-chrome-stable
# - jq (for JSON parsing)
#
# SETUP:
# Add to your niri config.kdl:
#   binds {
#       Mod+X { spawn "bash" "/path/to/this/script.sh"; }
#   }
# Replace Mod+X with your preferred key combination.

ON="/tmp/claude-toggle-niri-on"
OFF="/tmp/claude-toggle-niri-off"

launch_claude() {
  # Launch Claude as a Chrome app window
  # - Uses dedicated profile to isolate from main browser
  # - Custom class name "KagiAssistant" for window identification
  # - Floating window sized at 200x400 pixels
  # - Runs in background to avoid blocking
  google-chrome-stable \
    --app=https://claude.ai \
    --class="KagiAssistant" \
    --user-data-dir=$HOME/.config/claude-chrome \
    --profile-directory="KagiAssistant" \
    --app-id=kagiassistant \
    --app-name="Kagi Assistant" \
    --no-default-browser-check \
    --new-window \
    --window-size=1800,1000 \
    --disable-extensions \
    --disable-background-mode \
    --disk-cache-dir=/tmp/kagi-assistant-cache \
    --no-first-run &
}

get_window_id() {
  # Query niri for the window ID of the KagiAssistant app
  # Returns the first matching window ID (there should only be one)
  niri msg -j windows 2>/dev/null | jq -r '.[] | select(.app_id | test("KagiAssistant")) | .id' | head -n1
}

get_current_workspace() {
  # Get the index of the currently focused workspace
  # Used to know where to move the window when showing it
  niri msg -j workspaces 2>/dev/null | jq -r '.[] | select(.is_focused == true) | .idx'
}

get_focused_output() {
  # Get the name of the currently focused monitor/output
  # This is used to move the window to the correct monitor
  niri msg -j workspaces 2>/dev/null | jq -r '.[] | select(.is_focused == true) | .output'
}

show_window() {
  # Move the Claude window to the current monitor and workspace, then focus it
  local window_id=$(get_window_id)
  local current_workspace=$(get_current_workspace)
  local focused_output=$(get_focused_output)

  if [[ -n "$window_id" && -n "$current_workspace" && -n "$focused_output" ]]; then
    # First, move window to the focused monitor
    # This ensures the window appears on the monitor you're currently using
    niri msg action move-window-to-monitor --id "$window_id" "$focused_output" 2>/dev/null || true

    # Then move window to current workspace on that monitor
    niri msg action move-window-to-workspace --window-id "$window_id" "$current_workspace" 2>/dev/null || true

    # CRITICAL: Switch focus to floating layout
    # Chrome app windows are floating, so we need to explicitly switch focus
    # from the tiled layout to the floating layout for the window to receive focus
    niri msg action switch-focus-between-floating-and-tiling 2>/dev/null || true
  fi
  rm -f "$OFF"
  touch "$ON"
}

hide_window() {
  # Hide the window by moving it to workspace 99 (unused workspace)
  # Using --focus false prevents workspace 99 from being created/focused
  local window_id=$(get_window_id)
  if [[ -n "$window_id" ]]; then
    niri msg action move-window-to-workspace --window-id "$window_id" --focus false 99 2>/dev/null || true
  fi
  rm -f "$ON"
  touch "$OFF"
}

# MAIN TOGGLE LOGIC
# Check if the Chrome process is running and handle state transitions

if pgrep -f "class=KagiAssistant" >/dev/null; then
  # Process is running - determine what action to take based on state files
  if [[ ! -f "$ON" && ! -f "$OFF" ]]; then
    # State is unknown (neither file exists) - restart for clean state
    # This can happen after reboot or if state files were manually removed
    pkill -f "class=KagiAssistant"
    sleep 0.3
    rm -f "$ON" "$OFF"
    launch_claude
    show_window
  elif [[ -f "$ON" ]]; then
    # Window is currently visible - hide it
    hide_window
  elif [[ -f "$OFF" ]]; then
    # Window is currently hidden - show it
    show_window
  fi
else
  # No running process - launch and mark as ON
  # Note: We don't call show_window here because the window will be created
  # on the current workspace by default, and just needs to be marked as ON
  rm -f "$ON" "$OFF"
  launch_claude
  touch "$ON"
fi
