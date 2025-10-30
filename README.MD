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

### Enable the the systemd services
After the `make stow`, run `systemctl --user daemon-reload`. 

```
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now ydotoold.service
systemctl --user enable --now kanshi.service
systemctl --user enable --now solaar.service
systemctl --user enable --now swaybg.service
systemctl --user enable --now swayidle.service
systemctl --user enable --now ssh-agent.service
```

### Kanshi - Dynamic monitor configuration
Find out the output names via `niri msg outputs`. Then change the `./config/kanshi/config`.

### Waybar - Status bar
Any changes requires a `systemctl --user restart waybar`. Y ou can debug any errors on waybar execution using `journalctl --user -u waybar -f`. 
