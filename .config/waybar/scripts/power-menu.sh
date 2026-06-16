#!/usr/bin/env bash

# Power menu options
shutdown="󰐥  Shutdown"
reboot="󰜉  Restart"
logout="󰍃  Logout"
lock="  Lock"

# Show menu using fuzzel
chosen=$(echo -e "$shutdown\n$reboot\n$logout\n$lock" | fuzzel --dmenu --prompt "Power Menu: ")

case "$chosen" in
"$shutdown")
  systemctl poweroff
  ;;
"$reboot")
  systemctl reboot
  ;;
"$logout")
  swaymsg exit
  ;;
"$lock")
  swaylock
  ;;
esac
