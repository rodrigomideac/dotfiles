#!/usr/bin/env bash
set -uo pipefail

# Only one menu at a time — clicking the bar button twice shouldn't stack menus.
if pgrep -f 'fuzzel --dmenu --prompt Power Menu' >/dev/null; then
  exit 0
fi

# Power menu options (least destructive first — fuzzel preselects the top entry)
lock="󰌾  Lock"
suspend="󰒲  Sleep"
logout="󰍃  Logout"
reboot="󰜉  Restart"
shutdown="󰐥  Shutdown"

# fuzzel has no config here, so its default `monospace` font lacks the Nerd Font
# glyphs above. Pin the same font waybar uses so the icons actually render.
chosen=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
  fuzzel --dmenu --prompt "Power Menu: " \
    --font "Iosevka Nerd Font:size=14" \
    --lines 5 --width 24) || exit 0

case "$chosen" in
"$lock")
  # -f daemonizes once the screen is actually locked, so the lock survives a
  # waybar restart instead of dying with its parent.
  swaylock -f
  ;;
"$suspend")
  # swayidle's before-sleep hook locks the screen for us.
  systemctl suspend
  ;;
"$logout")
  niri msg action quit --skip-confirmation
  ;;
"$reboot")
  systemctl reboot
  ;;
"$shutdown")
  systemctl poweroff
  ;;
esac
