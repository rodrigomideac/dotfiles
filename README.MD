# Dotfiles

## Getting started

You need to have these dependencies installed before using this config. 

```
numlockx
terminator
arandr
xrandr
rofi
i3-lock-fancy
setxkbmap
feh
qalculate-gtk
pavucontrol
amixer
playerctl
scrot
xclip
```

Edit the `Makefile` file to match your config path, and then run `make stow` to create the symlinks.

Note: `stow` will fail if the destination folders and files already exist. Make sure to copy or delete them before running `make stow`


### Further Configuration

# Ranger
To open Ranger in its workspace via rofi, we need to run it inside a `terminator` window named "ranger". Edit your `/usr/share/applications/ranger.desktop` Exec entry to `terminator -T "ranger" -e "ranger"` instead of only `ranger`
