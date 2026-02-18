#!/bin/bash
#
# Install Neovim via AppImage (>= 0.11).
# Can be run standalone or sourced from bootstrap.sh.
#
# Usage:
#   ./install-neovim.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers only if not already loaded (i.e. standalone mode)
if [ -z "${DISTRO:-}" ]; then
    source "$SCRIPT_DIR//lib/lib.sh"
    detect_distro
    detect_sudo
fi

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

install_neovim
