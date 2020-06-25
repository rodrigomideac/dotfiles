# Dotfiles

These are my dotfiles that I use on my i3wm setup, with rofi and polybar.

The central point of this setup is to always open certain applications in specific workspaces. For now, I use this division:

- Workspace 1: Chrome Browser
- Workspace 2: Development IDEs
- Workspace 3: Terminals
- Workspace 4: Secondary Terminals (currently no bindings to this workspace)
- Workspace 5: File Browsers (Ranger and Dolphin)
- Workspace 6: Virtualbox
- Workspace 8: Spotify
- Workspace 9: Slack

## Getting started

You need to have at least these dependencies installed before using this config. I'm pretty sure there are many others that I have installed since my first boot, so I apologise if any dependency is missing from this list.

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
dunst
```

Edit the `Makefile` file to match your config path, and then run `make stow` to create the symlinks.

Note: `stow` will fail if the destination folders and files already exist. Make sure to copy or delete them before running `make stow`.

## Further Configuration

### Fonts

You might need these fonts to proper render some icons in the polybar:

- [Font Awesome 4 (version 5 is not used)](https://aur.archlinux.org/packages/ttf-font-awesome-4/)
- [Siji](https://aur.archlinux.org/packages/siji-git)

### VIM
The `.vimrc` config file needs to have the [vim-plug](https://github.com/junegunn/vim-plug) installed.


### Enable the services
So far, this config relies only on [NetworkManager](https://wiki.archlinux.org/index.php?title=NetworkManager) service. Make sure to install its package, enable and start its service via:

```
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service
```

### Desktop Notifications
Some apps, such as Slack and Spotify, can crash if a desktop notification server is not running.
- Install [notification-daemon](https://www.archlinux.org/packages/?name=notification-daemon)
- Install [dunst](https://www.archlinux.org/packages/?name=dunst)

You can test if everything is ok by running in a shell `notify-send 'Hello world!' 'This is an example notification.' --icon=dialog-information`.

### Ranger
To open Ranger in its workspace via rofi, we need to run it inside a `terminator` window named "ranger". Edit your `/usr/share/applications/ranger.desktop` Exec entry to `terminator -T "ranger" -e "ranger"` instead of only `ranger`.

### Screen tearing on Nvidia-cards
In `nvidia-settings` -> X Server Display Configuration, set either Force Composition Pipeline or Force Full Composition Pipeline to true.
