#!/bin/bash
# Cycle through power-profiles-daemon profiles: power-saver → balanced → performance
# Each press advances to the next profile and shows a notification.
# Requires: powerprofilesctl, notify-send

set -euo pipefail

current=$(powerprofilesctl get)

case "$current" in
    power-saver)  next="balanced"     ;;
    balanced)     next="performance"  ;;
    performance)  next="power-saver"  ;;
    *)
        notify-send "Power Profile" "Unknown profile: $current" --icon=battery
        exit 1
        ;;
esac

powerprofilesctl set "$next"
notify-send "Power Profile" "Switched to $next" --icon=battery
