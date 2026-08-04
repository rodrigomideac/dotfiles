#!/bin/bash
#
# Install the niri desktop environment (compositor + companion stack):
# bar, launcher, notifications, lock/idle, wallpaper, clipboard, screenshots,
# media/backlight keys, Solaar (Logitech), and the XDG portal backends. Also
# installs the Solaar Logitech udev rule so it works without root.
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
    "pavucontrol:PulseAudio/PipeWire volume + per-app output routing (waybar pulseaudio click)"
    "brightnessctl:Backlight control (niri/waybar brightness keys)"
    "solaar:Logitech receiver/device manager (niri user service + keymaps)"
    "blueman:Bluetooth device manager (GTK applet + pairing)"
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
    "pavucontrol:PulseAudio/PipeWire volume + per-app output routing (waybar pulseaudio click)"
    "brightnessctl:Backlight control (niri/waybar brightness keys)"
    "solaar:Logitech receiver/device manager (niri user service + keymaps)"
    "blueman:Bluetooth device manager (GTK applet + pairing)"
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
    if [ "$DISTRO" = "debian" ] || [ "$DISTRO" = "ubuntu" ]; then
        # --no-install-recommends: without this, apt pulls in Recommends
        # transitively (e.g. xdg-desktop-portal-gnome -> gnome-shell ->
        # gnome-session-bin -> gdm3), which on a system with an existing
        # display manager (e.g. Kubuntu's sddm) triggers an interactive
        # debconf prompt asking which display manager should be default.
        # This setup deliberately doesn't install a display manager (see
        # print_summary in bootstrap.sh), so skip recommends entirely.
        $SUDO apt install -y --no-install-recommends "${pkg_names[@]}" || error "Failed to install desktop packages"
    else
        $SUDO $PKG_INSTALL "${pkg_names[@]}" || error "Failed to install desktop packages"
    fi
    log "Desktop environment installed"
}

# Solaar needs a udev rule granting the seated user raw hidraw access to
# Logitech receivers — without it Solaar runs read-only (or needs root). The
# solaar package ships a rule in /usr/lib/udev/rules.d, but the repo's rule
# (udev/42-logitech-unify-permissions.rules) also covers the Lenovo nano
# receiver and uses uaccess tagging, so install that one into /etc/udev (higher
# precedence). solaar.service itself is deployed + enabled by 'make stow' via
# niri.service.wants, so nothing to enable here. Idempotent.
install_solaar_udev_rule() {
    local repo_root rule
    repo_root="$(cd "$SCRIPT_DIR/../.." && pwd)"
    rule="$repo_root/udev/42-logitech-unify-permissions.rules"

    if [ ! -f "$rule" ]; then
        log "Solaar udev rule not found at $rule, skipping"
        return
    fi

    log "Installing Solaar Logitech udev rule into /etc/udev/rules.d"
    $SUDO cp "$rule" /etc/udev/rules.d/ || error "Failed to copy Solaar udev rule"
    $SUDO chown root:root /etc/udev/rules.d/42-logitech-unify-permissions.rules
    $SUDO chmod 644 /etc/udev/rules.d/42-logitech-unify-permissions.rules
    $SUDO udevadm control --reload-rules || true
    $SUDO udevadm trigger || true
}

# The Ubuntu niri PPA ships systemd user services for these and enables them
# system-wide (via graphical-session.target). But our niri config already
# spawns waybar/mako/kanshi through spawn-at-startup, so leaving the services
# enabled launches a SECOND copy of each (e.g. two waybars). Disable them so
# niri is the only launcher. dms.service is DankMaterialShell, the PPA's own
# desktop shell, which this waybar/niri setup doesn't use. swaybg/swayidle are
# left alone — niri doesn't spawn them, so their services aren't duplicated.
# No-op on Arch, where none of these are enabled by default.
disable_redundant_services() {
    local units=(waybar.service mako.service kanshi.service dms.service)
    log "Disabling redundant services (niri spawns its own): ${units[*]}"
    # Global scope = system-wide PPA enablement. Needs root; no user bus required.
    $SUDO systemctl --global disable "${units[@]}" 2>/dev/null || true
    # User scope too, if a user systemd instance is reachable here.
    systemctl --user disable --now "${units[@]}" 2>/dev/null || true
}

install_desktop_packages
install_solaar_udev_rule
disable_redundant_services
