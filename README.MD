# Dotfiles

These are my dotfiles that I use on my niri setup.

TODO: change the pic
![Desktop Picture](imgs/rmc-desktop.png "Desktop Picture")


## Getting started

You need to have these dependencies installed before using this config. The dependencies are organized by category for easier installation.

### Core Window Manager & Desktop
```
sudo pacman -S niri fuzzel swaybg swaylock xwayland-satellite xdg-desktop-portal-hyprland evince mako swayidle waybar plasma-polkit-agent udiskie kanshi swaymsg
```

### Essential tools 
```
sudo pacman -S \
alacritty \
zsh \
nemo \
neovim \
firefox \
atuin \
solaar \
curl
```

### Optional tools
```
yay -S \
jetbrains-toolbox \
insomnia \
virtualenv \
kubectx \
aws-cli \
nvm \
tldr \
google-chrome \
spotify \
slack \
```

Edit the `Makefile` file to match your config path, and then run `make stow` to create the symlinks.

Note: `stow` will fail if the destination folders and files already exist. Make sure to copy or delete them before running `make stow`.

## Further Configuration

### Fonts

You might need these fonts to proper render some icons:

- [Font Awesome 4 (version 5 is not used)](https://aur.archlinux.org/packages/ttf-font-awesome-4/)
- [Siji](https://aur.archlinux.org/packages/siji-git)
- [Noto Sans](https://www.archlinux.org/packages/extra/any/noto-fonts/)
- [Fira Code](https://www.archlinux.org/packages/community/any/ttf-fira-code/)

### Enable the services
So far, this config relies only on [NetworkManager](https://wiki.archlinux.org/index.php?title=NetworkManager) service. Make sure to install its package, enable and start its service via:

```
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service
```

### Kanshi - Dynamic monitor configuration
Find out the output names via `niri msg outputs`. Then change the `./config/kanshi/config`.

### Waybar - Status bar
Any changes requires a `systemctl --user restart waybar`. You can debug any errors on waybar execution using `journalctl --user -u waybar -f`. 
