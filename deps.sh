#!/bin/sh
echo "Installing dependendencies..."

# OhMyZsh + Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo pacman -Syu
sudo pacman -S vim
sudo pacman -S ranger
sudo pacman -S --needed kwallet ksshaskpass kwalletmanager
sudo pacman -S virtualenv
sudo pacman -S kubectx
sudo pacman -S bluez bluez-utils
sudo pacman -S snap

yay slack
yay kdialog
yay google-chrome
echo "Please set your default browser"
kcmshell5 componentchooser 
yay vscode
yay jetbrains-toolbox
yay nvm
yay kube-ps1
yay aws-cli
yay github
yay insomnia
yay blueman
yay spotify
yay snap
yay code
yay vscode
yay pavucontrol
yay maim
yay playerctl
yay ttf-font-awesome-4
yay siji-git
yay noto-fonts
yay ttf-fira-code
yay tldr

# Vimplug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# SDK man for JDK management
sudo pacman -S zip unzip
curl -s "https://get.sdkman.io" | bash

