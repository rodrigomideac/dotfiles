#!/bin/bash
#
# Shared helper functions for bootstrap scripts.
# Source this file from other scripts:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#

log() {
    echo "[bootstrap] $*"
}

error() {
    echo "[bootstrap] ERROR: $*" >&2
    exit 1
}

# Detect Linux distribution and set PKG_UPDATE / PKG_INSTALL globals.
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

# Detect if running as root and set SUDO global.
detect_sudo() {
    if [ "$EUID" -eq 0 ]; then
        log "Running as root"
        SUDO=""
    else
        log "Running as non-root user, will use sudo"
        SUDO="sudo"
    fi
}
