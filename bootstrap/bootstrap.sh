#!/bin/bash
#
# Bootstrap script for dotfiles installation
# Supports Debian, Ubuntu, and Manjaro/Arch
#
# Two modes of operation:
#   Remote mode: When run via curl|bash or from outside ~/.dotfiles, clones the
#                repo to ~/.dotfiles and re-execs itself in local mode.
#   Local mode:  When run from inside ~/.dotfiles, performs the full setup
#                (install deps, oh-my-zsh, neovim, stow configs, etc.).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/refs/heads/master/bootstrap/bootstrap.sh | bash
#   ~/.dotfiles/bootstrap/bootstrap.sh
#
# Options:
#   --yes, -y          Skip interactive prompts (auto-confirm)
#   --desktop          Install the niri desktop environment without prompting
#   --no-desktop       Skip the desktop environment without prompting
#
# By default the script installs only the CLI/dev toolchain and, at the end,
# interactively asks whether to also install the niri desktop environment
# (compositor, bar, launcher, notifications, lock/idle, wallpaper, clipboard,
# screenshots, portals). The desktop install is independent of --yes: an
# unattended run installs the desktop only when --desktop is passed.
#
# Environment variables:
#   DOTFILES_REPO_URL  Git URL to clone dotfiles from (default: GitHub repo)
#                      Supports any git-compatible URL (https, ssh, local path).
#                      Example: DOTFILES_REPO_URL=/path/to/local/repo ./bootstrap.sh
#   BOOTSTRAP_YES      Set to 1 to skip interactive prompts (same as --yes)
#   INSTALL_DESKTOP    Set to 1 (same as --desktop) or 0 (same as --no-desktop)
#

set -e  # Exit on error

# ==============================================================================
# Configuration
# ==============================================================================

DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/rodrigomideac/dotfiles.git}"
DOTFILES_DIR="$HOME/.dotfiles"

# ==============================================================================
# Parse flags
# ==============================================================================

for arg in "$@"; do
    case "$arg" in
        --yes|-y) BOOTSTRAP_YES=1 ;;
        --desktop) INSTALL_DESKTOP=1 ;;
        --no-desktop) INSTALL_DESKTOP=0 ;;
    esac
done

# ==============================================================================
# Mode detection
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""

if [ -f "$SCRIPT_DIR/lib/lib.sh" ] && [ "$SCRIPT_DIR" = "$DOTFILES_DIR/bootstrap" ]; then
    MODE="local"
else
    MODE="remote"
fi

# ==============================================================================
# Remote mode — clone repo and hand off to local mode
# ==============================================================================

remote_mode() {
    echo "[bootstrap] Running in remote mode..."

    if ! command -v git >/dev/null 2>&1; then
        echo "[bootstrap] ERROR: git is required but not installed." >&2
        echo "[bootstrap] Install it first:" >&2
        echo "[bootstrap]   Debian/Ubuntu: apt install -y git" >&2
        echo "[bootstrap]   Arch/Manjaro:  pacman -S --noconfirm git" >&2
        exit 1
    fi

    if [ -d "$DOTFILES_DIR" ]; then
        if [ "${BOOTSTRAP_YES:-0}" = "1" ]; then
            echo "[bootstrap] Removing existing $DOTFILES_DIR..."
            rm -rf "$DOTFILES_DIR"
        else
            echo "[bootstrap] $DOTFILES_DIR already exists."
            printf "[bootstrap] Remove it and re-clone? [y/N] "
            read -r answer < /dev/tty
            case "$answer" in
                [yY]|[yY][eE][sS])
                    echo "[bootstrap] Removing $DOTFILES_DIR..."
                    rm -rf "$DOTFILES_DIR"
                    ;;
                *)
                    echo "[bootstrap] Aborting."
                    exit 1
                    ;;
            esac
        fi
    fi

    echo "[bootstrap] Cloning dotfiles from $DOTFILES_REPO_URL..."
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR" || {
        echo "[bootstrap] ERROR: Failed to clone dotfiles" >&2
        exit 1
    }
    echo "[bootstrap] Dotfiles cloned to $DOTFILES_DIR"

    exec "$DOTFILES_DIR/bootstrap/bootstrap.sh" "$@"
}

if [ "$MODE" = "remote" ]; then
    remote_mode "$@"
    exit 0
fi

# ==============================================================================
# Local mode — full setup from inside ~/.dotfiles
# ==============================================================================

source "$SCRIPT_DIR/lib/lib.sh"

# Package arrays: "package_name:description"

DEBIAN_PACKAGES=(
    "build-essential:Build tools (gcc, make, etc.)"
    "fontconfig:Font cache/management (fc-cache, fc-list)"
    "fonts-powerline:Powerline fonts for zsh themes"
    "unzip:Archive extraction (required by Mason)"
    "python3:Python interpreter (required by Mason)"
    "python3-venv:Python virtual environments (required by Mason)"
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
    "fontconfig:Font cache/management (fc-cache, fc-list)"
    "powerline-fonts:Powerline fonts for zsh themes"
    "unzip:Archive extraction (required by Mason)"
    "python:Python interpreter (required by Mason)"
    "xxd:Hex dump utility"
    "xclip:Clipboard utility"
    "xsel:Clipboard utility"
    "tmux:Terminal multiplexer"
    "zoxide:Smarter cd command"
    "ripgrep:Fast grep alternative"
    "jq:JSON processor"
)

# The optional niri desktop environment is defined in (and installed by)
# lib/install-desktop.sh, which can also be run standalone to install ONLY the
# desktop stack.

# ==============================================================================
# Global Variables
# ==============================================================================

DISTRO=""
PKG_UPDATE=""
PKG_INSTALL=""
SUDO=""
DESKTOP_INSTALLED=0

# ==============================================================================
# Functions
# ==============================================================================

# Clean all existing configurations for fresh install
clean_existing_configs() {
    log "Cleaning existing configurations for fresh install..."

    # Remove oh-my-zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Removing ~/.oh-my-zsh..."
        rm -rf "$HOME/.oh-my-zsh"
    fi

    # Remove configs that would conflict with stow
    for f in "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf"; do
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
    "$SCRIPT_DIR/lib/install-neovim.sh"
}

# Install the Nerd Fonts referenced by the desktop configs
install_fonts() {
    "$SCRIPT_DIR/lib/install-fonts.sh"
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

# Install the niri desktop environment (compositor + companion stack).
# The package list, niri PPA handling, and install logic live in the standalone
# lib/install-desktop.sh so they can also be run on their own.
install_desktop_packages() {
    "$SCRIPT_DIR/lib/install-desktop.sh"
    DESKTOP_INSTALLED=1
}

# Decide whether to install the desktop environment (flag or interactive prompt)
maybe_install_desktop() {
    case "${INSTALL_DESKTOP:-}" in
        1)
            log "Installing desktop environment (requested via --desktop)"
            ;;
        0)
            log "Skipping desktop environment (--no-desktop)"
            return
            ;;
        *)
            # No explicit flag: prompt interactively. A piped install
            # (curl|bash) still has a controlling terminal at /dev/tty.
            if [ ! -e /dev/tty ]; then
                log "Non-interactive run without --desktop; skipping desktop environment"
                log "  (re-run with --desktop to install niri and the companion stack)"
                return
            fi
            echo ""
            log "Optional: install the niri desktop environment?"
            log "  niri, waybar, fuzzel, mako, swaylock, swayidle, swaybg, kanshi,"
            log "  alacritty, xwayland-satellite, wl-clipboard, cliphist, grim, slurp,"
            log "  solaar, and the GNOME/GTK XDG portal backends."
            printf "[bootstrap] Install the desktop environment now? [y/N] "
            local answer=""
            read -r answer < /dev/tty || answer=""
            case "$answer" in
                [yY]|[yY][eE][sS]) ;;
                *) log "Skipping desktop environment install"; return ;;
            esac
            ;;
    esac
    install_desktop_packages
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

# Install node and go via mise (required by Mason for LSP servers, formatters, etc.)
install_mise_tools() {
    if ! which mise &>/dev/null; then
        error "mise not found in PATH, cannot install node/go"
    fi

    log "Installing node and go via mise..."

    if ! mise which node &>/dev/null; then
        log "Installing node 22..."
        mise use --global node@22 || error "Failed to install node 22 via mise"
    else
        log "node already installed via mise, skipping"
    fi

    if ! mise which go &>/dev/null; then
        log "Installing go 1.25..."
        mise use --global go@1.25 || error "Failed to install go 1.25 via mise"
    else
        log "go already installed via mise, skipping"
    fi

    # Activate mise shims for the rest of the script
    eval "$(mise activate bash --shims)"
    log "node $(node --version) and go $(go version) available"
}

# Prepare filesystem for stow by removing conflicting files/dirs
prepare_stow_targets() {
    log "Preparing stow targets..."

    # Create directories that stow targets into
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.local/bin"

    # Remove files that conflict with stow symlinks from HOME-targeted packages
    for f in "$HOME/.zshrc" "$HOME/.vimrc" "$HOME/.tmux.conf"; do
        if [ -f "$f" ] || [ -L "$f" ]; then
            log "Removing $f (conflicts with stow)..."
            rm -f "$f"
        fi
    done

    # Remove .config subdirs that conflict with stow symlinks
    local config_dirs=(
        alacritty atuin autostart fontconfig
        io.datasette.llm kanshi mise niri nvim
        ranger solaar systemd waybar
    )
    for d in "${config_dirs[@]}"; do
        if [ -d "$HOME/.config/$d" ] || [ -L "$HOME/.config/$d" ]; then
            log "Removing ~/.config/$d (conflicts with stow)..."
            rm -rf "$HOME/.config/$d"
        fi
    done

    log "Stow targets prepared"
}

# Setup Neovim plugins and Mason tools (requires nvim config already deployed via stow)
install_nvim() {
    log "Setting up Neovim plugins and Mason tools..."
    make -C "$DOTFILES_DIR/.config/nvim" configure
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
    echo "  - Installed Nerd Fonts (FiraCode, Iosevka) into ~/.local/share/fonts"
    echo "  - Installed mise and atuin"
    echo "  - Dotfiles at $DOTFILES_DIR"
    echo "  - Deployed all configs via 'make stow'"
    echo "  - Set zsh as default shell"

    echo ""
    if [ "$DESKTOP_INSTALLED" = "1" ]; then
        log "Installed the niri desktop environment:"
        echo "  - niri / xwayland-satellite   Compositor + X11 support"
        echo "  - waybar / fuzzel / mako      Bar, launcher, notifications"
        echo "  - swaylock / swayidle / swaybg  Lock, idle, wallpaper"
        echo "  - kanshi                      Display/monitor configuration"
        echo "  - alacritty                   Terminal emulator"
        echo "  - wl-clipboard / cliphist     Clipboard + history"
        echo "  - grim / slurp                Screenshots"
        echo "  - playerctl / brightnessctl   Media + backlight keys"
        echo "  - solaar                      Logitech device manager (+ udev rule)"
        echo "  - xdg-desktop-portal-gnome/-gtk  Portal backends"
        echo ""
        log "Not installed (opinionated / machine-specific — add yourself if needed):"
        echo "  - A display manager (GDM, etc.) — or start niri from a TTY with 'niri-session'"
        echo "  - PipeWire + WirePlumber — the volume keys call 'wpctl' (install if missing)"
        echo "  - A browser       google-chrome-stable / firefox"
    else
        log "Desktop environment NOT installed."
        echo "  Re-run with --desktop (or answer 'y' at the prompt) to install:"
        echo "  niri, waybar, fuzzel, mako, swaylock, swayidle, swaybg, kanshi,"
        echo "  alacritty, xwayland-satellite, wl-clipboard, cliphist, grim, slurp, solaar, portals."
        echo "  Still install separately: a display manager, brightnessctl, a browser."
    fi

    echo ""
    log "Additional make targets you can run:"
    echo "  make stow-sudo  - Deploy systemd services (requires sudo)"
    echo "  make stow-work  - Deploy bash .profile config (work environments)"

    echo ""
    log "Next steps:"
    echo "  1. Logout and log back in (or run 'exec zsh')"
    if [ "$DESKTOP_INSTALLED" = "1" ]; then
        echo "  2. Log out and choose 'niri' in your display manager (or run 'niri-session' from a TTY)"
        echo "  3. niri spawns waybar/mako/swaybg/etc. via 'spawn-at-startup' in"
        echo "     ~/.config/niri/config.kdl — make sure those are enabled, or the bar/"
        echo "     notifications won't appear even though they're installed."
    else
        echo "  2. Enjoy your new environment!"
    fi
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

    # Install all system packages
    install_packages

    # Install Nerd Fonts required by alacritty/waybar (needs unzip + fontconfig)
    install_fonts

    # Install special packages (mise, atuin)
    install_special_packages

    # Install node and go via mise (required by Mason)
    install_mise_tools

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

    # Optionally install the niri desktop environment (opt-in prompt)
    maybe_install_desktop

    # Summary
    print_summary
}

main "$@"
