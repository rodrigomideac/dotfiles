#!/bin/bash
#
# Install the niri desktop environment (compositor + companion stack):
# bar, launcher, notifications, lock/idle, wallpaper, clipboard, screenshots,
# media/backlight keys, and the XDG portal backends.
#
# Distro-agnostic. Most packages come from the official repos (Ubuntu
# 'universe' / Arch 'extra'). niri and xwayland-satellite are not in Ubuntu's
# default archive, so on Ubuntu this adds the niri PPA first.
#
# Can be run standalone (install ONLY the desktop stack, nothing else) or
# sourced/invoked from bootstrap.sh.
#
# Usage:
#   ./install-desktop.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared helpers only if not already loaded (i.e. standalone mode)
if [ -z "${DISTRO:-}" ]; then
    source "$SCRIPT_DIR/lib.sh"
    detect_distro
    detect_sudo
fi

# Package arrays: "package_name:description". Names differ only for mako
# (mako-notifier on Debian/Ubuntu, mako on Arch).
DEBIAN_DESKTOP_PACKAGES=(
    "niri:Scrollable-tiling Wayland compositor"
    "waybar:Status bar"
    "fuzzel:Application launcher"
    "mako-notifier:Notification daemon (mako)"
    "swaybg:Wallpaper setter"
    "swaylock:Screen locker"
    "swayidle:Idle management daemon"
    "kanshi:Dynamic display/monitor configuration"
    "alacritty:Terminal emulator"
    "xwayland-satellite:Xwayland support for X11 apps"
    "wl-clipboard:Wayland clipboard (wl-copy/wl-paste)"
    "cliphist:Clipboard history (used by niri startup script)"
    "grim:Screenshot capture"
    "slurp:Screen-region selector"
    "playerctl:Media player control (waybar module + media keys)"
    "brightnessctl:Backlight control (niri/waybar brightness keys)"
    "xdg-desktop-portal-gnome:XDG portal backend (screencast, global shortcuts)"
    "xdg-desktop-portal-gtk:XDG portal backend (file chooser, settings)"
)

ARCH_DESKTOP_PACKAGES=(
    "niri:Scrollable-tiling Wayland compositor"
    "waybar:Status bar"
    "fuzzel:Application launcher"
    "mako:Notification daemon"
    "swaybg:Wallpaper setter"
    "swaylock:Screen locker"
    "swayidle:Idle management daemon"
    "kanshi:Dynamic display/monitor configuration"
    "alacritty:Terminal emulator"
    "xwayland-satellite:Xwayland support for X11 apps"
    "wl-clipboard:Wayland clipboard (wl-copy/wl-paste)"
    "cliphist:Clipboard history (used by niri startup script)"
    "grim:Screenshot capture"
    "slurp:Screen-region selector"
    "playerctl:Media player control (waybar module + media keys)"
    "brightnessctl:Backlight control (niri/waybar brightness keys)"
    "xdg-desktop-portal-gnome:XDG portal backend (screencast, global shortcuts)"
    "xdg-desktop-portal-gtk:XDG portal backend (file chooser, settings)"
)

# niri and xwayland-satellite are not in Ubuntu's default archive; this PPA
# provides them (everything else comes from 'universe' / the Arch 'extra' repo).
NIRI_PPA="ppa:avengemedia/danklinux"

# Ensure the niri PPA is configured (Ubuntu only). Idempotent.
add_niri_ppa() {
    if grep -rqs "avengemedia/danklinux" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        log "niri PPA ($NIRI_PPA) already configured, skipping"
        return
    fi
    log "Adding niri PPA: $NIRI_PPA"
    # add-apt-repository lives in software-properties-common on minimal installs.
    if ! command -v add-apt-repository >/dev/null 2>&1; then
        $SUDO $PKG_UPDATE || error "Failed to update package manager"
        $SUDO $PKG_INSTALL software-properties-common || error "Failed to install software-properties-common"
    fi
    $SUDO add-apt-repository -y "$NIRI_PPA" || error "Failed to add niri PPA ($NIRI_PPA)"
}

install_desktop_packages() {
    local packages
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
        packages=("${DEBIAN_DESKTOP_PACKAGES[@]}")
    else
        packages=("${ARCH_DESKTOP_PACKAGES[@]}")
    fi

    local pkg_names=()
    for pkg_spec in "${packages[@]}"; do
        IFS=':' read -r pkg_name description <<< "$pkg_spec"
        pkg_names+=("$pkg_name")
    done

    # niri/xwayland-satellite need a PPA on Ubuntu. On Debian niri ships in the
    # official repos (testing/sid), so don't add an Ubuntu-only PPA there.
    if [ "$DISTRO" = "ubuntu" ]; then
        add_niri_ppa
    fi

    log "Installing niri desktop environment: ${pkg_names[*]}"
    # Refresh the package index first — it may not have run yet in this context.
    $SUDO $PKG_UPDATE || error "Failed to update package manager"
    $SUDO $PKG_INSTALL "${pkg_names[@]}" || error "Failed to install desktop packages"
    log "Desktop environment installed"
}

install_desktop_packages
