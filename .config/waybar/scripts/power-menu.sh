#!/usr/bin/env bash

# Power menu options
shutdown="󰐥  Shutdown"
reboot="󰜉  Restart"
logout="󰍃  Logout"
lock="  Lock"

# Show menu using rofi
chosen=$(echo -e "$shutdown\n$reboot\n$logout\n$lock" | rofi -dmenu -i -p "Power Menu" -theme-str 'window {width: 500px;}')

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
