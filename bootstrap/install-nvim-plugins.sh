#!/bin/bash
#
# Install Neovim plugins (Lazy) and Mason tools in headless mode.
# Extracted from bootstrap.sh for robustness and reusability.
#
# Usage:
#   ./install-nvim-plugins.sh              # Full install (clear state, Lazy sync, Mason tools)
#   ./install-nvim-plugins.sh --debug-mason # Clear mason cache only, run mason install
#
# Environment variables:
#   MASON_TIMEOUT  Timeout in seconds for Mason tool installation (default: 600)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[nvim-setup] $*"
}

if [ "$1" = "--debug-mason" ]; then
    log "Debug mode: clearing mason cache and running mason install only..."
    rm -rf "$HOME/.local/share/nvim/mason"
    log "Removed ~/.local/share/nvim/mason"

    log "Installing Mason tools..."
    if nvim --headless +"luafile $SCRIPT_DIR/install-mason-tools.lua"; then
        log "Mason tools installed successfully"
    else
        log "Warning: Mason tools install had issues (exit code: $?)"
    fi

    log "Done"
    exit 0
fi

# Clear all nvim state/cache for a clean install
log "Clearing nvim state/cache..."
for d in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
    if [ -d "$d" ]; then
        log "Removing $d..."
        rm -rf "$d"
    fi
done

# Step 1: Install Lazy plugins
log "Installing Lazy plugins..."
if nvim --headless "+Lazy! sync" +qa; then
    log "Lazy plugins installed successfully"
else
    log "Warning: Lazy plugin sync had issues (exit code: $?)"
fi

# Step 2: Install Mason tools via event-driven Lua script
log "Installing Mason tools..."
if nvim --headless +"luafile $SCRIPT_DIR/install-mason-tools.lua"; then
    log "Mason tools installed successfully"
else
    log "Warning: Mason tools install had issues (exit code: $?)"
fi

log "Neovim setup complete"
