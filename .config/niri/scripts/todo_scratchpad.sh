#!/bin/bash
# Toggle Todo window - show/hide scratchpad-style behavior
#
# OVERVIEW:
# This script provides a dropdown/scratchpad-style toggle for a todo file.
# It launches alacritty with nvim editing the todo file and allows you to show/hide it across
# workspaces using a keyboard shortcut.
#
# STATE MANAGEMENT:
# Uses two temporary files to track window state:
#   - ON:  Window is visible on current workspace
#   - OFF: Window is hidden (moved to workspace 99)
#   - Neither: Process is running but state is unknown (triggers restart)
#
# BEHAVIOR:
# 1. If no process running: Launch alacritty and mark as ON
# 2. If process running with no state files: Kill and restart (clean state)
# 3. If state is ON: Hide window (move to workspace 99) and mark OFF
# 4. If state is OFF: Show window (move to current workspace) and mark ON
#
# WINDOW FOCUSING:
# The alacritty window is in the floating layout. After moving it to the current
# workspace, we call switch-focus-between-floating-and-tiling to ensure it receives
# focus. This is necessary because niri's default focus may remain on tiled windows.
#
# REQUIREMENTS:
# - niri window manager with IPC enabled
# - alacritty
# - nvim
# - jq (for JSON parsing)
#
# SETUP:
# Add to your niri config.kdl:
#   binds {
#       Mod+Z { spawn "bash" "/path/to/this/script.sh"; }
#   }
# Replace Mod+Z with your preferred key combination.

ON="/tmp/todo-toggle-niri-on"
OFF="/tmp/todo-toggle-niri-off"

launch_todo() {
  # Launch alacritty with nvim editing the todo file
  # - Custom class name "TodoScratchpad" for window identification
  # - Floating window with custom dimensions
  # - Runs in background to avoid blocking
  alacritty \
    --class="TodoScratchpad" \
    -o window.dimensions.columns=150 \
    -o window.dimensions.lines=50 \
    -e nvim ~/dev/notes/todo.md &
}

get_window_id() {
  # Query niri for the window ID of the TodoScratchpad app
  # Returns the first matching window ID (there should only be one)
  niri msg -j windows 2>/dev/null | jq -r '.[] | select(.app_id == "TodoScratchpad") | .id' | head -n1
}

get_current_workspace() {
  # Get the index of the currently focused workspace
  # Used to know where to move the window when showing it
  niri msg -j workspaces 2>/dev/null | jq -r '.[] | select(.is_focused == true) | .idx'
}

show_window() {
  # Move the todo window to the current workspace and focus it
  local window_id=$(get_window_id)
  local current_workspace=$(get_current_workspace)
  if [[ -n "$window_id" && -n "$current_workspace" ]]; then
    # Move window to current workspace
    niri msg action move-window-to-workspace --window-id "$window_id" "$current_workspace" 2>/dev/null || true
    # sleep 0.1  # Delay disabled - not needed

    # CRITICAL: Switch focus to floating layout
    # Alacritty windows are floating, so we need to explicitly switch focus
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
# Check if the alacritty process is running and handle state transitions

if pgrep -f "class=TodoScratchpad" >/dev/null; then
  # Process is running - determine what action to take based on state files
  if [[ ! -f "$ON" && ! -f "$OFF" ]]; then
    # State is unknown (neither file exists) - restart for clean state
    # This can happen after reboot or if state files were manually removed
    pkill -f "class=TodoScratchpad"
    sleep 0.3
    rm -f "$ON" "$OFF"
    launch_todo
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
  launch_todo
  touch "$ON"
fi
