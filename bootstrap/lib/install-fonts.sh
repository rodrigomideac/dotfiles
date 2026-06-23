#!/bin/bash
#
# Install the Nerd Fonts required by the desktop configs.
# Distro-agnostic: downloads font archives from the upstream nerd-fonts
# GitHub release into ~/.local/share/fonts. Works the same on Debian,
# Ubuntu, Manjaro/Arch and anything else with curl + unzip + fontconfig.
#
# Configs depending on these fonts:
#   .config/alacritty/alacritty.toml  -> FiraCode Nerd Font
#   .config/waybar/style.css          -> Iosevka Nerd Font
#
# Can be run standalone or sourced from bootstrap.sh.
#
# Usage:
#   ./install-fonts.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers only if not already loaded (i.e. standalone mode)
if [ -z "${DISTRO:-}" ]; then
    source "$SCRIPT_DIR/lib.sh"
    detect_distro
    detect_sudo
fi

# nerd-fonts release archives to install, as "Archive:Font Family" pairs.
# "Archive" is the release asset base name (https://github.com/ryanoasis/
# nerd-fonts/releases). "Font Family" is the family name used to check
# whether it is already installed (matches what the configs reference).
NERD_FONTS=(
    "FiraCode:FiraCode Nerd Font"
    "Iosevka:Iosevka Nerd Font"
)

NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

install_fonts() {
    if ! command -v unzip >/dev/null 2>&1; then
        error "unzip is required to install fonts but was not found"
    fi

    local fonts_dir="$HOME/.local/share/fonts"
    mkdir -p "$fonts_dir"

    local installed_any=false

    for spec in "${NERD_FONTS[@]}"; do
        IFS=':' read -r archive family <<< "$spec"

        # Skip if the family is already available to fontconfig.
        if command -v fc-list >/dev/null 2>&1 && fc-list | grep -qi "$family"; then
            log "$family already installed, skipping"
            continue
        fi

        log "Installing $family..."

        local temp_dir
        temp_dir=$(mktemp -d)
        local dest="$fonts_dir/${archive}NerdFont"

        if curl -fLo "$temp_dir/$archive.zip" "$NERD_FONTS_BASE_URL/$archive.zip"; then
            mkdir -p "$dest"
            # -o overwrite, -q quiet; ignore non-font cruft (LICENSE, readme).
            unzip -oq "$temp_dir/$archive.zip" '*.ttf' '*.otf' -d "$dest" \
                || unzip -oq "$temp_dir/$archive.zip" -d "$dest"
            installed_any=true
            log "$family installed to $dest"
        else
            log "Warning: failed to download $archive Nerd Font (non-fatal)"
        fi

        rm -rf "$temp_dir"
    done

    # Refresh the font cache so apps pick up the new fonts.
    if [ "$installed_any" = true ] && command -v fc-cache >/dev/null 2>&1; then
        log "Rebuilding font cache..."
        fc-cache -f "$fonts_dir" >/dev/null 2>&1 || true
    fi

    log "Fonts installed"
}

install_fonts
