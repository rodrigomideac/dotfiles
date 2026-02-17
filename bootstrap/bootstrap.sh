#!/bin/bash
#
# Bootstrap script for dotfiles installation
# Supports Debian, Ubuntu, and Manjaro/Arch
#
# Installs all dependencies, clones the repo to ~/.dotfiles, and runs `make stow`.
# Designed for ephemeral machines - always cleans and reinstalls everything.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/.../bootstrap.sh | bash
#   ./bootstrap.sh
#
# Environment variables:
#   DOTFILES_REPO_URL  Git URL to clone dotfiles from (default: GitHub repo)
#                      Supports any git-compatible URL (https, ssh, local path).
#                      Example: DOTFILES_REPO_URL=/path/to/local/repo ./bootstrap.sh
#

set -e  # Exit on error

# ==============================================================================
# Configuration
# ==============================================================================

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/rodrigomideac/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"

# Package arrays: "package_name:description"

DEBIAN_PACKAGES=(
    "build-essential:Build tools (gcc, make, etc.)"
    "fonts-powerline:Powerline fonts for zsh themes"
    "xxd:Hex dump utility"
    "xclip:Clipboard utility"
    "xsel:Clipboard utility"
    "tmux:Terminal multiplexer"
    "zoxide:Smarter cd command"
    "ripgrep:Fast grep alternative"
    "jq:JSON processor"
)

ARCH_PACKAGES=(
    "base-devel:Build tools (gcc, make, etc.)"
    "powerline-fonts:Powerline fonts for zsh themes"
    "xxd:Hex dump utility"
    "xclip:Clipboard utility"
    "xsel:Clipboard utility"
    "tmux:Terminal multiplexer"
    "zoxide:Smarter cd command"
    "ripgrep:Fast grep alternative"
    "jq:JSON processor"
)

# ==============================================================================
# Global Variables
# ==============================================================================

DISTRO=""
PKG_UPDATE=""
PKG_INSTALL=""
SUDO=""

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

# Clean all existing configurations for fresh install
clean_existing_configs() {
    log "Cleaning existing configurations for fresh install..."

    # Remove dotfiles repo
    if [ -d "$DOTFILES_DIR" ]; then
        log "Removing $DOTFILES_DIR..."
        rm -rf "$DOTFILES_DIR"
    fi

    # Remove oh-my-zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Removing ~/.oh-my-zsh..."
        rm -rf "$HOME/.oh-my-zsh"
    fi

    # Remove configs that would conflict with stow
    for f in "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf" "$HOME/.imwheelrc"; do
        if [ -f "$f" ] || [ -L "$f" ]; then
            log "Removing $f..."
            rm -f "$f"
        fi
    done

    # Remove nvim config
    if [ -d "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
        log "Removing ~/.config/nvim..."
        rm -rf "$HOME/.config/nvim"
    fi

    # Remove nvim data/cache (lazy, mason, etc.)
    for d in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        if [ -d "$d" ]; then
            log "Removing $d..."
            rm -rf "$d"
        fi
    done

    # Remove any backup files from previous runs
    rm -f "$HOME/.zshrc.backup."* 2>/dev/null || true
    rm -rf "$HOME/.config/nvim.backup."* 2>/dev/null || true

    log "Cleanup complete"
}

# Install core dependencies (curl, git, zsh, stow)
install_core_deps() {
    log "Checking core dependencies (curl, git, zsh, stow)..."

    local need_install=false
    command -v curl >/dev/null 2>&1 || need_install=true
    command -v git >/dev/null 2>&1 || need_install=true
    command -v zsh >/dev/null 2>&1 || need_install=true
    command -v stow >/dev/null 2>&1 || need_install=true

    if [ "$need_install" = false ]; then
        log "Core dependencies already installed, skipping"
        return
    fi

    log "Installing core dependencies..."
    $SUDO $PKG_UPDATE || error "Failed to update package manager"
    $SUDO $PKG_INSTALL curl git zsh stow sudo || error "Failed to install core dependencies"

    log "Core dependencies installed"
}

# Install oh-my-zsh (always required)
install_ohmyzsh() {
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || error "Failed to install Oh My Zsh"
    log "Oh My Zsh installed"
}

# Install neovim via AppImage (always required)
install_neovim() {
    if command -v nvim &>/dev/null; then
        # Check version - we need at least 0.11
        local version=$(nvim --version | head -1 | sed 's/NVIM v//' | cut -d. -f1,2)
        local major=$(echo "$version" | cut -d. -f1)
        local minor=$(echo "$version" | cut -d. -f2)

        if [ "$major" -gt 0 ] || [ "$minor" -ge 11 ]; then
            log "Neovim $version already installed (>= 0.11), skipping"
            return
        else
            log "Neovim $version is too old (< 0.11), removing..."
            $SUDO rm -rf /opt/nvim
            $SUDO rm -f /usr/bin/nvim /usr/local/bin/nvim
            # Try to remove package manager version if exists
            if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
                $SUDO apt remove -y neovim 2>/dev/null || true
            elif [ "$DISTRO" = "manjaro" ]; then
                $SUDO pacman -Rs --noconfirm neovim 2>/dev/null || true
            fi
        fi
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
        $SUDO ln -sf /opt/nvim/nvim /usr/bin/nvim
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

# Clone dotfiles repository
clone_dotfiles() {
    log "Cloning dotfiles from $DOTFILES_REPO_URL..."
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR" || error "Failed to clone dotfiles"
    log "Dotfiles cloned to $DOTFILES_DIR"
}

# Install all system packages
install_packages() {
    local packages
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
        packages=("${DEBIAN_PACKAGES[@]}")
    else
        packages=("${ARCH_PACKAGES[@]}")
    fi

    local pkg_names=()
    for pkg_spec in "${packages[@]}"; do
        IFS=':' read -r pkg_name description <<< "$pkg_spec"
        pkg_names+=("$pkg_name")
    done

    log "Installing packages: ${pkg_names[*]}"
    $SUDO $PKG_INSTALL "${pkg_names[@]}" || error "Failed to install packages"
    log "Package installation complete"
}

# Install special packages (mise, atuin)
install_special_packages() {
    # mise
    log "Installing mise..."
    if command -v mise &>/dev/null; then
        log "mise already installed, skipping"
    else
        curl https://mise.jdx.dev/install.sh | sh || log "Warning: Failed to install mise (non-fatal)"
    fi

    # atuin
    log "Installing atuin..."
    if command -v atuin &>/dev/null; then
        log "atuin already installed, skipping"
    else
        curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh || log "Warning: Failed to install atuin (non-fatal)"
    fi
}

# Prepare filesystem for stow by removing conflicting files/dirs
prepare_stow_targets() {
    log "Preparing stow targets..."

    # Create directories that stow targets into
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"

    # Remove files that conflict with stow symlinks from HOME-targeted packages
    for f in "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf" "$HOME/.imwheelrc" \
             "$HOME/.Xmodmap_clean" "$HOME/.Xmodmap_k56"; do
        if [ -f "$f" ] || [ -L "$f" ]; then
            log "Removing $f (conflicts with stow)..."
            rm -f "$f"
        fi
    done

    # Remove .config subdirs that conflict with stow symlinks
    local config_dirs=(
        alacritty atuin autostart dmenu-extended dunst feh fontconfig
        i3 io.datasette.llm kanshi mise niri nvim picom polybar
        ranger rofi systemd waybar
    )
    for d in "${config_dirs[@]}"; do
        if [ -d "$HOME/.config/$d" ] || [ -L "$HOME/.config/$d" ]; then
            log "Removing ~/.config/$d (conflicts with stow)..."
            rm -rf "$HOME/.config/$d"
        fi
    done

    # Remove nvim data/cache for clean editor state
    for d in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
        if [ -d "$d" ]; then
            log "Removing $d..."
            rm -rf "$d"
        fi
    done

    log "Stow targets prepared"
}

# Setup Neovim plugins and Mason tools (requires nvim config already deployed via stow)
install_nvim() {
    log "Setting up Neovim plugins and Mason tools..."
    "$DOTFILES_DIR/bootstrap/install-nvim-plugins.sh"
    log "Neovim plugins and Mason tools installed"
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

    log "What was done:"
    echo "  - Installed system packages and core dependencies"
    echo "  - Installed Oh My Zsh"
    echo "  - Installed Neovim (AppImage) with plugins and Mason tools"
    echo "  - Installed mise and atuin"
    echo "  - Cloned dotfiles to $DOTFILES_DIR"
    echo "  - Deployed all configs via 'make stow'"
    echo "  - Set zsh as default shell"

    echo ""
    log "Desktop/visual dependencies NOT installed (install separately):"
    echo "  - niri          Wayland compositor (window manager)"
    echo "  - kanshi        Display/monitor configuration"
    echo "  - waybar        Status bar"
    echo "  - fuzzel        Application launcher"
    echo "  - swaylock      Screen locker"
    echo "  - swaybg        Wallpaper setter"
    echo "  - swayidle      Idle management daemon"
    echo "  - alacritty     Terminal emulator"
    echo "  - dunst         Notification daemon"
    echo "  - brightnessctl Brightness control"
    echo "  - picom         X11 compositor (if using i3)"
    echo "  - i3            X11 window manager (alternative to niri)"
    echo "  - polybar       Status bar for i3"
    echo "  - rofi          App launcher for i3"
    echo "  - feh           Image viewer / wallpaper setter (X11)"
    echo "  - Browser       google-chrome-stable / firefox"

    echo ""
    log "Additional make targets you can run:"
    echo "  make stow-sudo  - Deploy systemd services (requires sudo)"
    echo "  make stow-work  - Deploy bash .profile config (work environments)"

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

    # Environment setup
    detect_distro
    detect_sudo

    # Clean existing configs for fresh install
    clean_existing_configs

    # Install core dependencies (curl, git, zsh, stow)
    install_core_deps

    # Install oh-my-zsh (always required)
    install_ohmyzsh

    # Install neovim via AppImage (always required)
    install_neovim

    # Clone dotfiles
    clone_dotfiles

    # Install all system packages
    install_packages

    # Install special packages (mise, atuin)
    install_special_packages

    # Prepare filesystem for stow
    prepare_stow_targets

    # Deploy all configs via stow
    log "Deploying configurations via 'make stow'..."
    make -C "$DOTFILES_DIR" stow || error "Failed to run 'make stow'"
    log "Configurations deployed"

    # Setup Neovim plugins and Mason tools (after stow deploys nvim config)
    install_nvim

    # Set default shell
    set_default_shell

    # Summary
    print_summary
}

main "$@"
