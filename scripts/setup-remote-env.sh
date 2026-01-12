#!/bin/bash
# setup-remote-env.sh - Remote environment setup script
# Purpose: Automate setup of ephemeral remote hosts with dev tools and configuration
# Repository: https://github.com/rodrigomideac/dotfiles

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Global variables
SCRIPT_VERSION="1.0.0"
DOTFILES_REPO="https://github.com/rodrigomideac/dotfiles.git"
DOTFILES_BRANCH="master"
TMP_DIR="/tmp/dotfiles-setup-$$"
SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6QfFvyZwY5lfjR+rTqF5NQIzeMI73NAS0h3oilaDTz"

# Package manager variables (set by detect_distro)
DISTRO=""
PKG_MANAGER=""
PKG_UPDATE=""
PKG_INSTALL=""

# detect_distro() - Identify the Linux distribution and set package manager
detect_distro() {
    echo "Detecting distribution..."

    if [ -f /etc/debian_version ]; then
        DISTRO="debian"
        PKG_MANAGER="apt"
        PKG_UPDATE="sudo apt update"
        PKG_INSTALL="sudo apt install -y"
        echo "✓ Detected Debian-based system"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        PKG_UPDATE="sudo pacman -Sy"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        echo "✓ Detected Arch-based system"
    else
        echo "✗ Unsupported distribution"
        echo "This script supports Debian and Arch-based systems only"
        exit 1
    fi
}

# install_packages() - Install required packages
install_packages() {
    echo "Installing packages..."

    # Update package database
    echo "Updating package database..."
    $PKG_UPDATE

    # Install packages
    PACKAGES="zsh cifs-utils smbclient git curl"
    echo "Installing: $PACKAGES"
    $PKG_INSTALL $PACKAGES

    echo "✓ Packages installed successfully"
}

# install_neovim_appimage() - Install Neovim from official AppImage
install_neovim_appimage() {
    echo "Installing Neovim from AppImage..."

    # Check if nvim is already installed
    if command -v nvim &> /dev/null; then
        echo "✓ Neovim already installed, skipping"
        return 0
    fi

    # Download AppImage
    echo "Downloading Neovim AppImage..."
    local tmp_appimage="/tmp/nvim-linux-x86_64.appimage"
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    mv nvim-linux-x86_64.appimage "$tmp_appimage"

    # Test if AppImage works
    if "$tmp_appimage" --version &> /dev/null; then
        echo "✓ AppImage works, installing globally..."
        sudo mkdir -p /opt/nvim
        sudo mv "$tmp_appimage" /opt/nvim/nvim
        sudo ln -sf /opt/nvim/nvim /usr/local/bin/nvim
    else
        echo "⚠ AppImage doesn't work, extracting..."
        "$tmp_appimage" --appimage-extract
        sudo mv squashfs-root /opt/nvim-squashfs
        sudo ln -sf /opt/nvim-squashfs/AppRun /usr/local/bin/nvim
        rm -f "$tmp_appimage"
    fi

    echo "✓ Neovim installed"
}

# install_oh_my_zsh() - Install oh-my-zsh framework in unattended mode
install_oh_my_zsh() {
    echo "Installing oh-my-zsh..."

    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "✓ oh-my-zsh already installed, skipping"
        return 0
    fi

    # Install oh-my-zsh in unattended mode
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo "✓ oh-my-zsh installed"
}

# set_default_shell() - Change user's default shell to zsh
set_default_shell() {
    echo "Setting zsh as default shell..."

    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
    ZSH_PATH=$(which zsh)

    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "✓ zsh is already the default shell"
        return 0
    fi

    # Change shell (requires sudo)
    sudo chsh -s "$ZSH_PATH" "$USER"

    echo "✓ Default shell set to zsh (will take effect on next login)"
}

# clone_dotfiles() - Clone dotfiles repository to temporary location
clone_dotfiles() {
    echo "Cloning dotfiles repository..."

    # Remove old temp directory if exists
    rm -rf "$TMP_DIR"

    # Clone repository
    git clone --depth 1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$TMP_DIR"

    echo "✓ Dotfiles cloned to $TMP_DIR"
}

# deploy_dotfiles() - Copy configuration files to home directory
deploy_dotfiles() {
    echo "Deploying dotfiles..."

    # Backup existing files if they exist
    if [ -f "$HOME/.zshrc" ]; then
        BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing .zshrc to $BACKUP_FILE"
        mv "$HOME/.zshrc" "$BACKUP_FILE"
    fi

    if [ -d "$HOME/.config/nvim" ]; then
        BACKUP_DIR="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing nvim config to $BACKUP_DIR"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
    fi

    # Copy .zshrc
    cp "$TMP_DIR/zsh/.zshrc" "$HOME/.zshrc"
    echo "✓ Copied .zshrc"

    # Copy nvim config
    mkdir -p "$HOME/.config"
    cp -r "$TMP_DIR/.config/nvim" "$HOME/.config/"
    echo "✓ Copied nvim configuration"

    # Note about optional dependencies
    echo ""
    echo "Note: Your .zshrc includes optional tools (mise, atuin, nvm, fzf, etc.)"
    echo "These are not installed by this script. Install them manually if needed."
    echo ""
}

# add_ssh_keys() - Add authorized SSH public key for remote access
add_ssh_keys() {
    echo "Adding SSH authorized keys..."

    # Create .ssh directory if not exists
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Check if key already exists
    if [ -f "$HOME/.ssh/authorized_keys" ] && grep -q "$SSH_PUBKEY" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
        echo "✓ SSH key already present"
        return 0
    fi

    # Append key
    echo "$SSH_PUBKEY" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"

    echo "✓ SSH key added to authorized_keys"
}

# create_mount_unit() - Create systemd mount unit file
# Parameters: $1 = share name (data or temp_data)
create_mount_unit() {
    local share_name=$1
    local mount_point="$HOME/mnt/$share_name"
    local unit_name=$(systemd-escape -p --suffix=mount "$mount_point")
    local unit_file="/etc/systemd/system/$unit_name"

    echo "Creating systemd mount unit: $unit_file"

    # Get actual UID/GID
    local uid=$(id -u)
    local gid=$(id -g)

    sudo tee "$unit_file" > /dev/null <<EOF
[Unit]
Description=Mount $share_name share from NAS
After=network-online.target
Wants=network-online.target

[Mount]
What=//nas.casa/$share_name
Where=$mount_point
Type=cifs
Options=credentials=$HOME/.smbcredentials,iocharset=utf8,noperm,gid=$gid,uid=$uid,_netdev

[Install]
WantedBy=multi-user.target
EOF

    echo "✓ Created $unit_file"
}

# create_mount_checker() - Create systemd timer and service for 15s mount retry
create_mount_checker() {
    echo "Creating mount checker service and timer..."

    # Create service template
    sudo tee /etc/systemd/system/nas-mount-checker@.service > /dev/null <<'EOF'
[Unit]
Description=Check and remount NAS share %i
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'mountpoint -q "%i" || systemctl start $(systemd-escape -p --suffix=mount "%i")'
EOF

    # Create timer template
    sudo tee /etc/systemd/system/nas-mount-checker@.timer > /dev/null <<'EOF'
[Unit]
Description=Check NAS mount %i every 15 seconds

[Timer]
OnBootSec=30s
OnUnitActiveSec=15s

[Install]
WantedBy=timers.target
EOF

    echo "✓ Mount checker created"
}

# setup_nas_mounts() - Interactively setup NAS mounts for home network
setup_nas_mounts() {
    echo ""
    echo "=== NAS Mount Setup ==="
    echo ""

    read -p "Are you on the home network? (y/n): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping NAS setup"
        return 0
    fi

    # Get credentials
    read -p "Enter NAS username: " nas_user
    read -s -p "Enter NAS password: " nas_pass
    echo

    # Create credentials file
    CREDS_FILE="$HOME/.smbcredentials"
    cat > "$CREDS_FILE" <<EOF
username=$nas_user
password=$nas_pass
EOF
    chmod 600 "$CREDS_FILE"
    echo "✓ Credentials saved to $CREDS_FILE"

    # Test connectivity
    echo "Testing NAS connectivity..."
    if ! smbclient -L //nas.casa -N 2>/dev/null; then
        echo "✗ Cannot reach NAS at //nas.casa"
        echo "Check network connection and try again"
        return 1
    fi
    echo "✓ NAS is reachable"

    # Create mount points
    mkdir -p "$HOME/mnt/data" "$HOME/mnt/temp_data"
    echo "✓ Created mount points"

    # Create mount units
    create_mount_unit "data"
    create_mount_unit "temp_data"

    # Create mount checker (for 15s retry)
    create_mount_checker

    # Enable and start
    sudo systemctl daemon-reload
    sudo systemctl enable "home-$USER-mnt-data.mount"
    sudo systemctl enable "home-$USER-mnt-temp_data.mount"
    sudo systemctl start "home-$USER-mnt-data.mount"
    sudo systemctl start "home-$USER-mnt-temp_data.mount"

    # Enable mount checkers
    sudo systemctl enable "nas-mount-checker@$HOME-mnt-data.timer"
    sudo systemctl enable "nas-mount-checker@$HOME-mnt-temp_data.timer"
    sudo systemctl start "nas-mount-checker@$HOME-mnt-data.timer"
    sudo systemctl start "nas-mount-checker@$HOME-mnt-temp_data.timer"

    echo "✓ NAS mounts configured and started"
}

# cleanup() - Remove temporary files
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        echo "Cleaning up..."
        rm -rf "$TMP_DIR"
        echo "✓ Cleanup complete"
    fi
}

# main() - Main orchestration function
main() {
    echo "========================================="
    echo "Remote Environment Setup Script v$SCRIPT_VERSION"
    echo "========================================="
    echo ""

    # Trap cleanup on exit
    trap cleanup EXIT

    # Run setup steps
    detect_distro
    install_packages
    install_neovim_appimage
    install_oh_my_zsh
    set_default_shell
    clone_dotfiles
    deploy_dotfiles
    add_ssh_keys
    setup_nas_mounts

    echo ""
    echo "========================================="
    echo "✓ Setup complete!"
    echo "========================================="
    echo ""
    echo "Next steps:"
    echo "1. Log out and log back in for zsh to become default shell"
    echo "2. Run 'nvim' to let Lazy.nvim install plugins"
    echo "3. Install optional tools mentioned in .zshrc if needed"
    echo ""
}

# Main execution
main "$@"
