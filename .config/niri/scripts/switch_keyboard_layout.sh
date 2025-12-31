#!/bin/bash
# Keyboard layout switcher for niri
# Toggles between thinkpad (ctrl:swapcaps) and split (no swapcaps) layouts
# Works by editing config.kdl directly, then reloading

CONFIG_FILE="$HOME/.config/niri/config.kdl"
STATE_FILE="/tmp/niri_keyboard_layout_state"

# Read current state (default to "thinkpad" if file doesn't exist)
if [ -f "$STATE_FILE" ]; then
    CURRENT_LAYOUT=$(cat "$STATE_FILE")
else
    CURRENT_LAYOUT="thinkpad"
fi

# Define the XKB configurations
THINKPAD_CONFIG="            // KEYBOARD_LAYOUT_MARKER_START
            // Current layout: thinkpad
            layout \"us\"
            variant \"intl\"
            options \"ctrl:swapcaps\"
            // KEYBOARD_LAYOUT_MARKER_END"

SPLIT_CONFIG="            // KEYBOARD_LAYOUT_MARKER_START
            // Current layout: split
            layout \"us\"
            variant \"intl\"
            // KEYBOARD_LAYOUT_MARKER_END"

# Toggle layout
if [ "$CURRENT_LAYOUT" = "thinkpad" ]; then
    NEW_LAYOUT="split"
    NEW_CONFIG="$SPLIT_CONFIG"
    NOTIFICATION="Switched to: Split (normal Caps Lock)"
else
    NEW_LAYOUT="thinkpad"
    NEW_CONFIG="$THINKPAD_CONFIG"
    NOTIFICATION="Switched to: ThinkPad (Caps = Ctrl)"
fi

# Create a temporary file with the new configuration
TEMP_FILE=$(mktemp)

# Use awk to replace the section between markers
awk -v new_config="$NEW_CONFIG" '
/KEYBOARD_LAYOUT_MARKER_START/ {
    print new_config
    skip=1
    next
}
/KEYBOARD_LAYOUT_MARKER_END/ {
    skip=0
    next
}
!skip {
    print
}
' "$CONFIG_FILE" > "$TEMP_FILE"

# Replace the original config file
mv "$TEMP_FILE" "$CONFIG_FILE"

# Save new state
echo "$NEW_LAYOUT" > "$STATE_FILE"

# Reload niri configuration to apply the changes
niri msg action load-config-file

# Show notification
notify-send -t 2000 "Keyboard Layout" "$NOTIFICATION"

echo "Switched to $NEW_LAYOUT layout"
