# Setup Remote Environment Script - Implementation Specification v1

## 1. Overview

**Purpose:** Automate the setup of ephemeral remote hosts with essential development tools and configuration.

**Target Systems:** Debian-based and Arch-based Linux distributions

**Delivery Method:** Curl-able script from GitHub raw URL

**Repository:** https://github.com/rodrigomideac/dotfiles

**Script Location:** `scripts/setup-remote-env.sh`

## 2. Requirements

### 2.1 Functional Requirements

1. **Distro Detection:** Auto-detect Debian vs Arch-based systems
2. **Package Installation:** Install zsh, neovim, oh-my-zsh, cifs-utils, smbclient
3. **Shell Configuration:** Set zsh as default shell with oh-my-zsh
4. **Dotfiles Deployment:** Copy .zshrc and .config/nvim configuration
5. **SSH Access:** Add authorized SSH public key
6. **Optional NAS Setup:** Interactive setup for home network NAS mounts

### 2.2 Non-Functional Requirements

1. **Idempotent:** Safe to run multiple times without breaking existing setup
2. **User-Friendly:** Clear progress messages and error handling
3. **Secure:** Proper file permissions, credential handling
4. **Minimal Dependencies:** Only install critical tools
5. **Network Resilient:** Handle network failures gracefully

### 2.3 Constraints

- Must use `sudo` for privileged operations (not run as root)
- Must not require user interaction except for NAS setup
- Must work offline for non-NAS features (after package installation)

## 3. Script Structure

```bash
#!/bin/bash
# setup-remote-env.sh - Remote environment setup script

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Global variables
SCRIPT_VERSION="1.0.0"
DOTFILES_REPO="https://github.com/rodrigomideac/dotfiles.git"
DOTFILES_BRANCH="master"
TMP_DIR="/tmp/dotfiles-setup-$$"
SSH_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6QfFvyZwY5lfjR+rTqF5NQIzeMI73NAS0h3oilaDTz"

# Functions
detect_distro()           # Detect OS and set PKG_MANAGER
check_requirements()      # Verify basic requirements (sudo, network)
install_packages()        # Install required packages
install_oh_my_zsh()       # Install oh-my-zsh framework
set_default_shell()       # Set zsh as default shell
clone_dotfiles()          # Clone dotfiles repo to temp location
deploy_dotfiles()         # Copy config files to home directory
add_ssh_keys()            # Add authorized SSH keys
setup_nas_mounts()        # Interactive NAS mount setup
create_mount_unit()       # Create systemd mount unit (helper)
create_mount_checker()    # Create systemd timer/service for mount checking
cleanup()                 # Remove temporary files
main()                    # Main orchestration function

# Main execution
main "$@"
```

## 4. Detailed Implementation

### 4.1 detect_distro()

**Purpose:** Identify the Linux distribution and set appropriate package manager

**Logic:**
```bash
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
```

### 4.2 install_packages()

**Purpose:** Install required packages in specified order

**Packages:** zsh, neovim, cifs-utils, smbclient, git, curl

**Logic:**
```bash
install_packages() {
    echo "Installing packages..."

    # Update package database
    $PKG_UPDATE

    # Install packages
    PACKAGES="zsh neovim cifs-utils smbclient git curl"
    $PKG_INSTALL $PACKAGES

    echo "✓ Packages installed successfully"
}
```

**Error Handling:**
- If package installation fails, print error and exit
- Check if packages are already installed to avoid reinstalling

### 4.3 install_oh_my_zsh()

**Purpose:** Install oh-my-zsh framework in unattended mode

**Logic:**
```bash
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
```

### 4.4 set_default_shell()

**Purpose:** Change user's default shell to zsh

**Logic:**
```bash
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
```

### 4.5 clone_dotfiles() & deploy_dotfiles()

**Purpose:** Clone dotfiles repo and copy configuration files

**Logic:**
```bash
clone_dotfiles() {
    echo "Cloning dotfiles repository..."

    # Remove old temp directory if exists
    rm -rf "$TMP_DIR"

    # Clone repository
    git clone --depth 1 --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$TMP_DIR"

    echo "✓ Dotfiles cloned to $TMP_DIR"
}

deploy_dotfiles() {
    echo "Deploying dotfiles..."

    # Backup existing files if they exist
    if [ -f "$HOME/.zshrc" ]; then
        echo "Backing up existing .zshrc to .zshrc.backup"
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    fi

    if [ -d "$HOME/.config/nvim" ]; then
        echo "Backing up existing nvim config to .config/nvim.backup"
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
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
```

### 4.6 add_ssh_keys()

**Purpose:** Add authorized SSH public key for remote access

**Logic:**
```bash
add_ssh_keys() {
    echo "Adding SSH authorized keys..."

    # Create .ssh directory if not exists
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Check if key already exists
    if grep -q "$SSH_PUBKEY" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
        echo "✓ SSH key already present"
        return 0
    fi

    # Append key
    echo "$SSH_PUBKEY" >> "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"

    echo "✓ SSH key added to authorized_keys"
}
```

### 4.7 setup_nas_mounts()

**Purpose:** Interactively setup NAS mounts for home network

**Flow:**
1. Ask if on home network
2. If yes, prompt for credentials
3. Test connectivity
4. Create mount points
5. Create systemd units
6. Enable and start mounts

**Logic:**
```bash
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
```

### 4.8 create_mount_unit()

**Purpose:** Create systemd mount unit file

**Parameters:** $1 = share name (data or temp_data)

**Logic:**
```bash
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
```

### 4.9 create_mount_checker()

**Purpose:** Create systemd timer and service for 15s mount retry

**Logic:**
```bash
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
```

### 4.10 cleanup()

**Purpose:** Remove temporary files

**Logic:**
```bash
cleanup() {
    echo "Cleaning up..."
    rm -rf "$TMP_DIR"
    echo "✓ Cleanup complete"
}
```

### 4.11 main()

**Purpose:** Orchestrate the entire setup process

**Logic:**
```bash
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
```

## 5. Edge Cases and Error Handling

### 5.1 Network Failures
- Wrap git clone and oh-my-zsh install in error checks
- Provide clear error messages with troubleshooting steps
- Allow script to continue if NAS setup fails

### 5.2 Existing Configuration
- Backup existing .zshrc and nvim config with timestamp
- Check if oh-my-zsh already installed before reinstalling
- Check if SSH key already exists before appending

### 5.3 Permission Issues
- Verify sudo access at start
- Set proper permissions on .ssh (700) and authorized_keys (600)
- Set proper permissions on .smbcredentials (600)

### 5.4 Unsupported Distributions
- Exit gracefully with helpful message
- Suggest manual installation steps

### 5.5 UID/GID Assumptions
- Use `id -u` and `id -g` instead of hardcoding 1000
- Use `$USER` and `$HOME` variables instead of hardcoded paths

### 5.6 Systemd Unit Naming
- Use `systemd-escape` to properly format mount point paths
- Handle spaces and special characters in paths

## 6. Testing Checklist

### 6.1 Debian-based System Test
- [ ] Run on fresh Ubuntu/Debian VM
- [ ] Verify all packages installed
- [ ] Verify zsh is default shell
- [ ] Verify .zshrc copied and sources correctly
- [ ] Verify nvim config copied and loads
- [ ] Verify SSH key in authorized_keys
- [ ] Test NAS setup (if on home network)
- [ ] Verify mounts active and accessible
- [ ] Verify mount checker timer running

### 6.2 Arch-based System Test
- [ ] Run on fresh Arch/Manjaro VM
- [ ] Same tests as Debian

### 6.3 Idempotency Test
- [ ] Run script twice
- [ ] Verify no errors on second run
- [ ] Verify no duplicate SSH keys
- [ ] Verify configs backed up, not overwritten

### 6.4 Edge Case Tests
- [ ] Run with existing .zshrc
- [ ] Run with existing nvim config
- [ ] Run without network access to NAS
- [ ] Run with wrong NAS credentials
- [ ] Verify mount retry works (disconnect NAS, reconnect)

## 7. Usage Examples

### 7.1 One-liner Curl Install
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/scripts/setup-remote-env.sh | bash
```

### 7.2 Inspect-Then-Run
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/scripts/setup-remote-env.sh -o setup.sh
less setup.sh  # Review the script
bash setup.sh
```

### 7.3 With Debug Output
```bash
bash -x setup.sh  # Run with debug output
```

## 8. Troubleshooting

### 8.1 Package Installation Fails
- Check internet connection
- Check if running as user with sudo access
- Verify package names are correct for distro

### 8.2 oh-my-zsh Installation Fails
- Check internet connection
- Verify curl is installed
- Check if .oh-my-zsh directory already exists

### 8.3 NAS Mounts Fail
- Verify on home network
- Check NAS hostname resolution: `ping nas.casa`
- Verify credentials are correct
- Check mount logs: `journalctl -u home-$USER-mnt-data.mount`

### 8.4 zsh Not Default After Login
- Run `echo $SHELL` to check
- Verify /etc/passwd has correct shell for user
- May need to re-login or reboot

### 8.5 Nvim Plugins Don't Load
- Run `:Lazy` in nvim to trigger plugin installation
- Check nvim version (should be recent)
- Check error messages in nvim

## 9. Security Considerations

1. **Credentials:** .smbcredentials file has 600 permissions
2. **SSH Keys:** Only authorized_keys file is modified, private keys never touched
3. **Sudo Usage:** Script uses sudo only for necessary operations
4. **Script Source:** Always verify script URL before curl-piping
5. **HTTPS:** All downloads use HTTPS (git, oh-my-zsh, curl)

## 10. Future Enhancements

- Support for more distributions (Fedora, openSUSE)
- Option to install all .zshrc dependencies
- Configuration file for customizing installed packages
- Dry-run mode to show what would be done
- Logging to file for debugging
- Automatic detection of home network (instead of prompting)

---

**Implementation Notes:**
- Use `set -e`, `set -u`, `set -o pipefail` for robust error handling
- Provide clear, colorful output messages (optional: use tput for colors)
- Make the script executable: `chmod +x setup-remote-env.sh`
- Test on both Debian and Arch before committing
