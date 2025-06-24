#!/bin/bash
set -e

echo "Installing comprehensive dotfiles dependencies for Manjaro..."
echo "This script uses yay to install packages from official repos and AUR"
echo ""

# Update system first
echo "Updating system..."
yay -Syu --noconfirm

echo ""
echo "=== Installing Core Window Manager & Desktop ==="
yay -S --noconfirm i3-wm polybar picom rofi dunst feh stow

echo ""
echo "=== Installing Terminal & Shell ==="
yay -S --noconfirm alacritty terminator zsh

# Install Oh My Zsh (if not already installed)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo ""
echo "=== Installing System Utilities ==="
yay -S --noconfirm networkmanager network-manager-applet blueman xorg-xrandr arandr xorg-setxkbmap numlockx xdotool yad redshift

echo ""
echo "=== Installing Audio & Media Controls ==="
yay -S --noconfirm pavucontrol alsa-utils playerctl

echo ""
echo "=== Installing Screen & Session Management ==="
yay -S --noconfirm i3lock-fancy betterlockscreen maim xclip

echo ""
echo "=== Installing File Management ==="
yay -S --noconfirm ranger dolphin

echo ""
echo "=== Installing Development Tools ==="
yay -S --noconfirm neovim vim google-chrome firefox code

# Install vim-plug for Neovim and Vim
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Install vim-plug for Neovim
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

echo ""
echo "=== Installing Communication & Entertainment ==="
yay -S --noconfirm spotify slack-desktop discord

echo ""
echo "=== Installing System Services & Security ==="
yay -S --noconfirm kwallet ksshaskpass kwalletmanager openssh notification-daemon

echo ""
echo "=== Installing Additional Utilities ==="
yay -S --noconfirm atuin i3-battery-popup solaar qalculate-gtk zenity kdialog curl

echo ""
echo "=== Installing Development Environment (Optional) ==="
yay -S --noconfirm jetbrains-toolbox insomnia python-virtualenv kubectx aws-cli nvm tldr

echo ""
echo "=== Installing Fonts ==="
yay -S --noconfirm ttf-font-awesome-4 siji-git noto-fonts ttf-fira-code

echo ""
echo "=== Installing Additional Tools from Original deps.sh ==="
yay -S --noconfirm bluez bluez-utils snapd github-cli

# Install SDKMAN for JDK management
echo ""
echo "=== Installing SDKMAN ==="
yay -S --noconfirm zip unzip
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
fi

echo ""
echo "=== Enabling Essential Services ==="
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service
sudo systemctl enable bluetooth.service
sudo systemctl start bluetooth.service

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "Next steps:"
echo "1. Edit the Makefile to match your config path"
echo "2. Run 'make stow' to create symlinks"
echo "3. Logout and login to use zsh as default shell"
echo "4. Run ':PlugInstall' in vim/neovim to install plugins"
echo "5. Configure your monitors by creating ~/.monitor-setup file"
echo ""
echo "Note: Some applications may require additional configuration:"
echo "- Set default browser: kcmshell5 componentchooser"
echo "- Test notifications: notify-send 'Hello world!' 'Test notification'"
echo "- Configure Nvidia settings if using Nvidia GPU"