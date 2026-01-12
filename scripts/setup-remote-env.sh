#!/bin/bash
# setup-remote-env.sh - Remote environment setup script
# Purpose: Automate setup of ephemeral remote hosts with dev tools and configuration
# Repository: https://github.com/rodrigomideac/dotfiles
# Install with curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/scripts/setup-remote-env.sh | bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Global variables
SCRIPT_VERSION="1.0.0"
DOTFILES_REPO="https://github.com/rodrigomideac/dotfiles.git"
DOTFILES_BRANCH="master"
TMP_DIR="/tmp/dotfiles-setup-$$"
SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6QfFvyZwY5lfjR+rTqF5NQIzeMI73NAS0h3oilaDTz"

# User and privilege variables (set by detect_user)
TARGET_USER=""
TARGET_HOME=""
SUDO_PREFIX=""

# Package manager variables (set by detect_distro)
DISTRO=""
PKG_MANAGER=""
PKG_UPDATE=""
PKG_INSTALL=""

# detect_user() - Determine target user and whether sudo is needed
detect_user() {
    echo "Detecting user context..."

    if [ "$(id -u)" -eq 0 ]; then
        # Running as root
        if [ -n "${SUDO_USER:-}" ]; then
            # Script was run with sudo, target the original user
            TARGET_USER="$SUDO_USER"
            TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
            echo "✓ Running as root via sudo, targeting user: $TARGET_USER"
        else
            # Script was run directly as root, target root itself
            TARGET_USER="root"
            TARGET_HOME="/root"
            echo "✓ Running directly as root, targeting root user"
        fi
        # No sudo prefix needed since we're already root
        SUDO_PREFIX=""
    else
        # Running as regular user
        TARGET_USER="$USER"
        TARGET_HOME="$HOME"
        SUDO_PREFIX="sudo"
        echo "✓ Running as user: $TARGET_USER, will use sudo for privileged operations"
    fi
}

# detect_distro() - Identify the Linux distribution and set package manager
detect_distro() {
    echo "Detecting distribution..."

    if [ -f /etc/debian_version ]; then
        DISTRO="debian"
        PKG_MANAGER="apt"
        PKG_UPDATE="$SUDO_PREFIX apt update"
        PKG_INSTALL="$SUDO_PREFIX apt install -y"
        echo "✓ Detected Debian-based system"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        PKG_MANAGER="pacman"
        PKG_UPDATE="$SUDO_PREFIX pacman -Sy"
        PKG_INSTALL="$SUDO_PREFIX pacman -S --noconfirm"
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
        $SUDO_PREFIX mkdir -p /opt/nvim
        $SUDO_PREFIX mv "$tmp_appimage" /opt/nvim/nvim
        $SUDO_PREFIX ln -sf /opt/nvim/nvim /usr/local/bin/nvim
    else
        echo "⚠ AppImage doesn't work, extracting..."
        "$tmp_appimage" --appimage-extract
        $SUDO_PREFIX mv squashfs-root /opt/nvim-squashfs
        $SUDO_PREFIX ln -sf /opt/nvim-squashfs/AppRun /usr/local/bin/nvim
        rm -f "$tmp_appimage"
    fi

    echo "✓ Neovim installed"
}

# install_oh_my_zsh() - Install oh-my-zsh framework in unattended mode
install_oh_my_zsh() {
    echo "Installing oh-my-zsh..."

    if [ -d "$TARGET_HOME/.oh-my-zsh" ]; then
        echo "✓ oh-my-zsh already installed, skipping"
        return 0
    fi

    # Install oh-my-zsh in unattended mode
    # When running as root for another user, we need to run the install as that user
    if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        su - "$TARGET_USER" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
    else
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    echo "✓ oh-my-zsh installed"
}

# set_default_shell() - Change user's default shell to zsh
set_default_shell() {
    echo "Setting zsh as default shell..."

    CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)
    ZSH_PATH=$(which zsh)

    if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
        echo "✓ zsh is already the default shell"
        return 0
    fi

    # Change shell
    $SUDO_PREFIX chsh -s "$ZSH_PATH" "$TARGET_USER"

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
    if [ -f "$TARGET_HOME/.zshrc" ]; then
        BACKUP_FILE="$TARGET_HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing .zshrc to $BACKUP_FILE"
        mv "$TARGET_HOME/.zshrc" "$BACKUP_FILE"
    fi

    if [ -d "$TARGET_HOME/.config/nvim" ]; then
        BACKUP_DIR="$TARGET_HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        echo "Backing up existing nvim config to $BACKUP_DIR"
        mv "$TARGET_HOME/.config/nvim" "$BACKUP_DIR"
    fi

    # Copy .zshrc
    cp "$TMP_DIR/zsh/.zshrc" "$TARGET_HOME/.zshrc"
    echo "✓ Copied .zshrc"

    # Clean up .zshrc to remove unnecessary tools
    echo "Cleaning up .zshrc..."
    sed -i 's/plugins=(git kube-ps1)/plugins=(git)/' "$TARGET_HOME/.zshrc"
    sed -i '/^source \$HOME\/\.cargo\/env$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^export PATH=\$PATH:\/usr\/local\/go\/bin$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^source \/usr\/share\/nvm\/init-nvm\.sh$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^# source \/opt\/kube-ps1\/kube-ps1\.sh$/d' "$TARGET_HOME/.zshrc"
    sed -i "/^PROMPT='\$(kube_ps1)'\$PROMPT$/d" "$TARGET_HOME/.zshrc"
    sed -i '/^source <(jj util completion zsh)$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^export FLYCTL_INSTALL=/d' "$TARGET_HOME/.zshrc"
    sed -i '/^export PATH="\$FLYCTL_INSTALL\/bin:\$PATH"$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^_uv_run_mod()/,/^}$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^compdef _uv_run_mod uv$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^eval "\$(mise activate zsh)"$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^# \. "\$HOME\/\.atuin\/bin\/env"$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^#eval "\$(atuin init zsh)"$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^eval "\$(atuin init zsh --disable-up-arrow)"$/d' "$TARGET_HOME/.zshrc"
    sed -i '/^alias nscala=/d' "$TARGET_HOME/.zshrc"
    sed -i '/^alias mr=/d' "$TARGET_HOME/.zshrc"
    sed -i '/workalias/d' "$TARGET_HOME/.zshrc"
    echo "✓ Cleaned up .zshrc"

    # Copy nvim config
    mkdir -p "$TARGET_HOME/.config"
    cp -r "$TMP_DIR/.config/nvim" "$TARGET_HOME/.config/"

    # Fix ownership if running as root for another user
    if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/.zshrc" "$TARGET_HOME/.config/nvim"
    fi

    echo "✓ Copied nvim configuration"
}

# add_ssh_keys() - Add authorized SSH public key for remote access
add_ssh_keys() {
    echo "Adding SSH authorized keys..."

    # Create .ssh directory if not exists
    mkdir -p "$TARGET_HOME/.ssh"
    chmod 700 "$TARGET_HOME/.ssh"

    # Check if key already exists
    if [ -f "$TARGET_HOME/.ssh/authorized_keys" ] && grep -q "$SSH_PUBKEY" "$TARGET_HOME/.ssh/authorized_keys" 2>/dev/null; then
        echo "✓ SSH key already present"
        return 0
    fi

    # Append key
    echo "$SSH_PUBKEY" >> "$TARGET_HOME/.ssh/authorized_keys"
    chmod 600 "$TARGET_HOME/.ssh/authorized_keys"

    # Fix ownership if running as root for another user
    if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/.ssh"
    fi

    echo "✓ SSH key added to authorized_keys"
}

# create_mount_unit() - Create systemd mount unit file
# Parameters: $1 = share name (data or temp_data)
create_mount_unit() {
    local share_name=$1
    local mount_point="$TARGET_HOME/mnt/$share_name"
    local unit_name=$(systemd-escape -p --suffix=mount "$mount_point")
    local unit_file="/etc/systemd/system/$unit_name"

    echo "Creating systemd mount unit: $unit_file"

    # Get actual UID/GID of target user
    local uid=$(id -u "$TARGET_USER")
    local gid=$(id -g "$TARGET_USER")

    $SUDO_PREFIX tee "$unit_file" > /dev/null <<EOF
[Unit]
Description=Mount $share_name share from NAS
After=network-online.target
Wants=network-online.target

[Mount]
What=//nas.casa/$share_name
Where=$mount_point
Type=cifs
Options=credentials=$TARGET_HOME/.smbcredentials,iocharset=utf8,noperm,gid=$gid,uid=$uid,_netdev

[Install]
WantedBy=multi-user.target
EOF

    echo "✓ Created $unit_file"
}

# create_mount_checker() - Create systemd timer and service for 15s mount retry
create_mount_checker() {
    echo "Creating mount checker service and timer..."

    # Create service template
    $SUDO_PREFIX tee /etc/systemd/system/nas-mount-checker@.service > /dev/null <<'EOF'
[Unit]
Description=Check and remount NAS share %i
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'mountpoint -q "%i" || systemctl start $(systemd-escape -p --suffix=mount "%i")'
EOF

    # Create timer template
    $SUDO_PREFIX tee /etc/systemd/system/nas-mount-checker@.timer > /dev/null <<'EOF'
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
    CREDS_FILE="$TARGET_HOME/.smbcredentials"
    cat > "$CREDS_FILE" <<EOF
username=$nas_user
password=$nas_pass
EOF
    chmod 600 "$CREDS_FILE"

    # Fix ownership if running as root for another user
    if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        chown "$TARGET_USER":"$TARGET_USER" "$CREDS_FILE"
    fi

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
    mkdir -p "$TARGET_HOME/mnt/data" "$TARGET_HOME/mnt/temp_data"

    # Fix ownership if running as root for another user
    if [ "$(id -u)" -eq 0 ] && [ "$TARGET_USER" != "root" ]; then
        chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/mnt"
    fi

    echo "✓ Created mount points"

    # Create mount units
    create_mount_unit "data"
    create_mount_unit "temp_data"

    # Create mount checker (for 15s retry)
    create_mount_checker

    # Get unit names based on actual mount points
    local data_mount_unit=$(systemd-escape -p --suffix=mount "$TARGET_HOME/mnt/data")
    local temp_data_mount_unit=$(systemd-escape -p --suffix=mount "$TARGET_HOME/mnt/temp_data")

    # Enable and start
    $SUDO_PREFIX systemctl daemon-reload
    $SUDO_PREFIX systemctl enable "$data_mount_unit"
    $SUDO_PREFIX systemctl enable "$temp_data_mount_unit"
    $SUDO_PREFIX systemctl start "$data_mount_unit"
    $SUDO_PREFIX systemctl start "$temp_data_mount_unit"

    # Enable mount checkers
    $SUDO_PREFIX systemctl enable "nas-mount-checker@$TARGET_HOME-mnt-data.timer"
    $SUDO_PREFIX systemctl enable "nas-mount-checker@$TARGET_HOME-mnt-temp_data.timer"
    $SUDO_PREFIX systemctl start "nas-mount-checker@$TARGET_HOME-mnt-data.timer"
    $SUDO_PREFIX systemctl start "nas-mount-checker@$TARGET_HOME-mnt-temp_data.timer"

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
    detect_user
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
