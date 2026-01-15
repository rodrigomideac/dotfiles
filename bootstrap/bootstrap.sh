#!/bin/bash
#
# Bootstrap script for dotfiles installation
# Supports Debian, Ubuntu, and Manjaro/Arch
# Prompts for each package individually with dynamic .zshrc cleanup
#

set -e  # Exit on error

# ==============================================================================
# Configuration
# ==============================================================================

DOTFILES_REPO_URL="https://github.com/rodrigomideac/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# Package arrays: "package_name:cleanup_key:description"
# cleanup_key is used to remove .zshrc references if package not installed

DEBIAN_PACKAGES=(
    "build-essential::Build tools (gcc, make, etc.)"
    "fonts-powerline::Powerline fonts for zsh themes"
    "xxd::Hex dump utility"
    "xclip::Clipboard utility"
    "xsel::Clipboard utility"
)

ARCH_PACKAGES=(
    "base-devel::Build tools (gcc, make, etc.)"
    "powerline-fonts::Powerline fonts for zsh themes"
    "xxd::Hex dump utility"
    "xclip::Clipboard utility"
    "xsel::Clipboard utility"
)

# Special packages (not in package manager, require custom installation)
# Note: oh-my-zsh is always installed (not optional)
SPECIAL_PACKAGES=(
    "mise:mise:Runtime version manager"
    "atuin:atuin:Shell history manager"
)

# ==============================================================================
# Global Variables
# ==============================================================================

INTERACTIVE=true
DISTRO=""
PKG_UPDATE=""
PKG_INSTALL=""
SUDO=""

declare -a INSTALLED_PACKAGES
declare -a SKIPPED_PACKAGES
declare -a CLEANUP_KEYS
declare -a INSTALLED_SPECIAL

# ==============================================================================
# Functions
# ==============================================================================

log() {
    echo "[bootstrap] $*"
}

error() {
    echo "[bootstrap] ERROR: $*" >&2
    exit 1
}

# Detect Linux distribution
detect_distro() {
    log "Detecting distribution..."

    if [ -f /etc/debian_version ]; then
        if grep -qi ubuntu /etc/os-release 2>/dev/null; then
            DISTRO="ubuntu"
        else
            DISTRO="debian"
        fi
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
    elif [ -f /etc/arch-release ]; then
        DISTRO="manjaro"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
    else
        error "Unsupported distribution"
    fi

    log "Detected: $DISTRO"
}

# Detect if running as root
detect_sudo() {
    if [ "$EUID" -eq 0 ]; then
        log "Running as root"
        SUDO=""
    else
        log "Running as non-root user, will use sudo"
        SUDO="sudo"
    fi
}

# Install core dependencies (curl, git, zsh)
install_core_deps() {
    log "Checking core dependencies (curl, git, zsh)..."

    # Check if already installed
    local need_install=false
    command -v curl >/dev/null 2>&1 || need_install=true
    command -v git >/dev/null 2>&1 || need_install=true
    command -v zsh >/dev/null 2>&1 || need_install=true

    if [ "$need_install" = false ]; then
        log "Core dependencies already installed, skipping"
        return
    fi

    log "Installing core dependencies..."
    $SUDO $PKG_UPDATE || error "Failed to update package manager"
    $SUDO $PKG_INSTALL curl git zsh sudo || error "Failed to install core dependencies"

    log "Core dependencies installed"
}

# Install oh-my-zsh (always required)
install_ohmyzsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Oh My Zsh already installed, skipping"
        return
    fi

    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || error "Failed to install Oh My Zsh"
    log "Oh My Zsh installed"
}

# Install neovim via AppImage (always required)
install_neovim() {
    if command -v nvim &>/dev/null; then
        log "Neovim already installed, skipping"
        return
    fi

    log "Installing Neovim via AppImage..."

    # Detect architecture
    local arch=$(uname -m)
    local appimage_name
    case "$arch" in
        x86_64) appimage_name="nvim-linux-x86_64.appimage" ;;
        aarch64|arm64) appimage_name="nvim-linux-arm64.appimage" ;;
        *) error "Unsupported architecture: $arch" ;;
    esac

    local temp_dir=$(mktemp -d)
    cd "$temp_dir"

    curl -LO "https://github.com/neovim/neovim/releases/latest/download/$appimage_name" || error "Failed to download Neovim AppImage"
    chmod u+x "$appimage_name"

    # Try running AppImage directly, fall back to extraction if FUSE unavailable
    if ./"$appimage_name" --version &>/dev/null; then
        # AppImage works directly - install to /opt/nvim
        $SUDO mkdir -p /opt/nvim
        $SUDO mv "$appimage_name" /opt/nvim/nvim
        $SUDO chmod +x /opt/nvim/nvim
        log "Neovim installed to /opt/nvim/nvim"
    else
        # AppImage doesn't work (no FUSE) - extract and install
        log "FUSE unavailable, extracting AppImage..."
        ./"$appimage_name" --appimage-extract >/dev/null 2>&1
        $SUDO rm -rf /opt/nvim
        $SUDO mv squashfs-root /opt/nvim
        $SUDO ln -sf /opt/nvim/AppRun /usr/bin/nvim
        log "Neovim extracted and installed to /opt/nvim"
    fi

    cd - >/dev/null
    rm -rf "$temp_dir"

    log "Neovim installed"
}

# Setup neovim plugins (Lazy, Mason, Treesitter)
setup_neovim_plugins() {
    log "Setting up Neovim plugins..."

    # Remove supermaven plugin (requires license)
    sed -i '/supermaven/d' "$HOME/.config/nvim/lazyvim.json"
    sed -i '/supermaven/d' "$HOME/.config/nvim/lazy-lock.json"

    nvim --headless "+Lazy! sync" "+MasonToolsInstallSync" "+TSUpdateSync" +qa || log "Warning: Neovim plugin setup had issues"
    log "Neovim plugins installed"
}

# Clone dotfiles repository
clone_dotfiles() {
    if [ -d "$DOTFILES_DIR" ]; then
        log "Dotfiles already present at $DOTFILES_DIR, skipping clone"
        return
    fi

    log "Cloning dotfiles from $DOTFILES_REPO_URL..."
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR" || error "Failed to clone dotfiles"
    log "Dotfiles cloned to $DOTFILES_DIR"
}

# Validate dotfiles structure
validate_dotfiles() {
    log "Validating dotfiles structure..."

    [ -f "$DOTFILES_DIR/zsh/.zshrc" ] || error "Missing zsh/.zshrc in dotfiles"
    [ -d "$DOTFILES_DIR/.config/nvim" ] || error "Missing .config/nvim in dotfiles"

    log "Dotfiles structure validated"
}

# Interactive package selection
select_packages_interactive() {
    log "=== Package Installation ==="
    echo "For each package, press Y to install, n to skip (default: Y)"
    echo ""

    # Select package array based on distro
    local packages
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
        packages=("${DEBIAN_PACKAGES[@]}")
    else
        packages=("${ARCH_PACKAGES[@]}")
    fi

    # Prompt for each package
    for pkg_spec in "${packages[@]}"; do
        IFS=':' read -r pkg_name cleanup_key description <<< "$pkg_spec"

        read -p "Install $description ($pkg_name)? [Y/n] " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Nn]$ ]]; then
            SKIPPED_PACKAGES+=("$pkg_name")
            [ -n "$cleanup_key" ] && CLEANUP_KEYS+=("$cleanup_key")
            log "Skipped: $pkg_name"
        else
            INSTALLED_PACKAGES+=("$pkg_name")
            log "Selected: $pkg_name"
        fi
    done

    # Prompt for special packages
    echo ""
    log "=== Special Packages ==="
    for pkg_spec in "${SPECIAL_PACKAGES[@]}"; do
        IFS=':' read -r pkg_name cleanup_key description <<< "$pkg_spec"

        read -p "Install $description? [Y/n] " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Nn]$ ]]; then
            CLEANUP_KEYS+=("$cleanup_key")
            log "Skipped: $pkg_name"
        else
            INSTALLED_SPECIAL+=("$pkg_name")
            log "Selected: $pkg_name"
        fi
    done
}

# Non-interactive package selection (install all)
select_packages_noninteractive() {
    log "Non-interactive mode: installing all packages"

    # Select package array based on distro
    local packages
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
        packages=("${DEBIAN_PACKAGES[@]}")
    else
        packages=("${ARCH_PACKAGES[@]}")
    fi

    # Add all packages to install list
    for pkg_spec in "${packages[@]}"; do
        IFS=':' read -r pkg_name cleanup_key description <<< "$pkg_spec"
        INSTALLED_PACKAGES+=("$pkg_name")
    done

    # Add all special packages
    for pkg_spec in "${SPECIAL_PACKAGES[@]}"; do
        IFS=':' read -r pkg_name cleanup_key description <<< "$pkg_spec"
        INSTALLED_SPECIAL+=("$pkg_name")
    done
}

# Install selected packages
install_packages() {
    if [ ${#INSTALLED_PACKAGES[@]} -eq 0 ]; then
        log "No packages to install"
        return
    fi

    log "Installing packages: ${INSTALLED_PACKAGES[*]}"

    local packages_to_install=()

    for pkg in "${INSTALLED_PACKAGES[@]}"; do
        # Check if package is already installed (rough check using command existence)
        case "$pkg" in
            neovim)
                command -v nvim >/dev/null 2>&1 || packages_to_install+=("$pkg")
                ;;
            build-essential|base-devel)
                command -v gcc >/dev/null 2>&1 || packages_to_install+=("$pkg")
                ;;
            *)
                # For other packages, assume they need to be installed
                packages_to_install+=("$pkg")
                ;;
        esac
    done

    if [ ${#packages_to_install[@]} -eq 0 ]; then
        log "All selected packages already installed"
        return
    fi

    for pkg in "${packages_to_install[@]}"; do
        log "Installing $pkg..."
        $SUDO $PKG_INSTALL "$pkg" || log "Warning: Failed to install $pkg (may already be installed)"
    done

    log "Package installation complete"
}

# Install special packages
install_special_packages() {
    for pkg in "${INSTALLED_SPECIAL[@]}"; do
        case "$pkg" in
            mise)
                log "Skipping mise installation (not available via package manager)"
                log "Visit https://mise.jdx.dev for installation instructions"
                CLEANUP_KEYS+=("mise")
                ;;
            atuin)
                log "Skipping atuin installation (not available via package manager)"
                log "Visit https://atuin.sh for installation instructions"
                CLEANUP_KEYS+=("atuin")
                ;;
        esac
    done
}

# Deploy configurations
deploy_configs() {
    log "Deploying configurations..."

    local timestamp=$(date +%Y%m%d_%H%M%S)

    # Backup and deploy .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        local backup="$HOME/.zshrc.backup.$timestamp"
        log "Backing up existing .zshrc to $backup"
        mv "$HOME/.zshrc" "$backup"
    fi

    cp "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc" || error "Failed to deploy .zshrc"

    # Remove kube-ps1 plugin (not included in bootstrap)
    sed -i 's/plugins=(git kube-ps1)/plugins=(git)/' "$HOME/.zshrc"
    sed -i '/kube_ps1/d' "$HOME/.zshrc"

    log "Deployed .zshrc"

    # Backup and deploy nvim config
    if [ -d "$HOME/.config/nvim" ]; then
        local backup="$HOME/.config/nvim.backup.$timestamp"
        log "Backing up existing nvim config to $backup"
        mv "$HOME/.config/nvim" "$backup"
    fi

    mkdir -p "$HOME/.config"
    cp -r "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim" || error "Failed to deploy nvim config"
    log "Deployed nvim config"
}

# Cleanup .zshrc for skipped packages
cleanup_zshrc() {
    if [ ${#CLEANUP_KEYS[@]} -eq 0 ]; then
        log "No cleanup needed for .zshrc"
        return
    fi

    log "Cleaning up .zshrc for skipped packages..."

    local zshrc="$HOME/.zshrc"

    for cleanup_key in "${CLEANUP_KEYS[@]}"; do
        case "$cleanup_key" in
            cargo)
                log "  Removing cargo references..."
                sed -i '/\.cargo\/env/d' "$zshrc"
                ;;
            nvm)
                log "  Removing nvm references..."
                sed -i '/NVM_DIR/d; /nvm\.sh/d; /init-nvm\.sh/d' "$zshrc"
                ;;
            kube-ps1)
                log "  Removing kubectl/kube-ps1 references..."
                sed -i '/kube-ps1/d; /kube_ps1/d' "$zshrc"
                # Remove kube-ps1 from plugins array
                sed -i 's/plugins=(\(.*\)kube-ps1\(.*\))/plugins=(\1\2)/' "$zshrc"
                ;;
            mise)
                log "  Removing mise references..."
                sed -i '/mise activate/d; /alias mr="mise run"/d' "$zshrc"
                ;;
            atuin)
                log "  Removing atuin references..."
                sed -i '/atuin/d' "$zshrc"
                ;;
            oh-my-zsh)
                log "  Removing oh-my-zsh framework..."
                sed -i '/ZSH=/d; /ZSH_THEME=/d; /plugins=/d; /source.*oh-my-zsh\.sh/d' "$zshrc"
                ;;
            jj)
                log "  Removing jj references..."
                sed -i '/jj util completion/d' "$zshrc"
                ;;
        esac
    done

    log "Cleaned up .zshrc"
}

# Set zsh as default shell
set_default_shell() {
    log "Setting zsh as default shell..."

    local zsh_path=$(which zsh)

    if [ -z "$zsh_path" ]; then
        error "zsh not found in PATH"
    fi

    if [ "$EUID" -eq 0 ]; then
        # Running as root
        chsh -s "$zsh_path" || log "Warning: Failed to set default shell"
    elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
        # Non-root with passwordless sudo - use usermod
        sudo usermod -s "$zsh_path" "$USER" || log "Warning: Failed to set default shell"
    else
        # Non-root without sudo - chsh will prompt for password
        chsh -s "$zsh_path" || log "Warning: Failed to set default shell (may require password)"
    fi

    log "Default shell set to zsh"
}

# Print summary
print_summary() {
    echo ""
    log "========================================="
    log "Bootstrap completed successfully!"
    log "========================================="
    echo ""

    log "Installed packages:"
    for pkg in "${INSTALLED_PACKAGES[@]}"; do
        echo "  - $pkg"
    done

    if [ ${#INSTALLED_SPECIAL[@]} -gt 0 ]; then
        echo ""
        log "Installed special packages:"
        for pkg in "${INSTALLED_SPECIAL[@]}"; do
            echo "  - $pkg"
        done
    fi

    if [ ${#SKIPPED_PACKAGES[@]} -gt 0 ]; then
        echo ""
        log "Skipped packages (references removed from .zshrc):"
        for pkg in "${SKIPPED_PACKAGES[@]}"; do
            echo "  - $pkg"
        done
    fi

    echo ""
    log "Deployed configurations:"
    echo "  - ~/.zshrc"
    echo "  - ~/.config/nvim/"

    echo ""
    log "Next steps:"
    echo "  1. Logout and log back in (or run 'exec zsh')"
    echo "  2. Enjoy your new environment!"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log "Starting bootstrap..."

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-interactive)
                INTERACTIVE=false
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Environment setup
    detect_distro
    detect_sudo

    # Install core dependencies
    install_core_deps

    # Install oh-my-zsh (always required)
    install_ohmyzsh

    # Install neovim via AppImage (always required)
    install_neovim

    # Clone dotfiles
    clone_dotfiles
    validate_dotfiles

    # Package selection
    if [ "$INTERACTIVE" = true ]; then
        select_packages_interactive
    else
        select_packages_noninteractive
    fi

    # Install packages
    install_packages
    install_special_packages

    # Deploy configs
    deploy_configs
    cleanup_zshrc

    # Setup neovim plugins
    setup_neovim_plugins

    # Set default shell
    set_default_shell

    # Summary
    print_summary
}

main "$@"
