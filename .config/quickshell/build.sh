#!/usr/bin/env bash
# Build Quickshell from source and install it into ~/.local.
#
# It is not packaged for Ubuntu, and it cannot be: Quickshell links against
# private Qt APIs, so a build is only valid for the exact Qt it was compiled
# against. Every time apt moves Qt6 forward this has to run again or the shell
# dies at startup on an ABI mismatch. That is also why the version is pinned
# here rather than tracking master -- a rebuild should change one thing at a
# time.
#
# Run from the repo root with `make quickshell`, or directly. Nothing built is
# committed: the source goes to ~/.local/src and the object files to ~/.cache,
# both outside the stow tree.
#
# Requires the Qt6 and Wayland development headers; the need() checks below
# name the package for anything missing.

set -euo pipefail

ref="${QS_REF:-v0.3.1}"
src_dir="$HOME/.local/src/quickshell"
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/build"
prefix="$HOME/.local"

need() {
    command -v "$1" >/dev/null || {
        printf 'quickshell: %s is not installed (%s)\n' "$1" "$2" >&2
        exit 1
    }
}

need cmake "apt install cmake"
need ninja "apt install ninja-build"
need git "apt install git"
need pkg-config "apt install pkg-config"

for mod in Qt6Qml Qt6Quick Qt6Widgets wayland-client; do
    pkg-config --exists "$mod" || {
        printf 'quickshell: %s development files are missing\n' "$mod" >&2
        printf '  apt install qt6-base-dev qt6-declarative-dev qt6-declarative-private-dev libwayland-dev\n' >&2
        exit 1
    }
done

if [[ -d "$src_dir/.git" ]]; then
    git -C "$src_dir" fetch --tags --quiet origin
else
    git clone --quiet https://github.com/quickshell-mirror/quickshell.git "$src_dir"
fi
git -C "$src_dir" checkout --quiet "$ref"

# cpptrace backs the crash handler and drags in zstd; without it the shell
# still runs, it just dies silently instead of restarting itself.
crash_handler=ON
if ! pkg-config --exists libzstd; then
    printf 'quickshell: libzstd-dev missing, building without the crash handler\n' >&2
    crash_handler=OFF
fi

# X11 and Hyprland are dead weight here: this is a pure Wayland desktop and the
# compositor is niri.
cmake -GNinja -B "$build_dir" -S "$src_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" \
    -DDISTRIBUTOR="dotfiles local build" \
    -DCRASH_HANDLER="$crash_handler" \
    -DX11=OFF \
    -DHYPRLAND=OFF

cmake --build "$build_dir"
cmake --install "$build_dir" >/dev/null

printf 'quickshell: installed %s (%s)\n' "$("$prefix/bin/quickshell" --version | head -1)" "$ref"
