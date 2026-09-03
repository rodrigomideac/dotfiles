#!/usr/bin/env bash
# Build the compiled niri helpers and install them into ~/.local/bin.
#
# These are the pieces that cannot be a shell script: niri-cursor-pos has to
# speak the Wayland protocol itself, because the pointer position is not in
# niri's IPC and no client can ask for it out of band.
#
# Run from the repo root with `make tools`, or directly. Nothing here is
# committed except the sources and the vendored protocol XML — the generated
# code goes to a build directory under ~/.cache and the binary to ~/.local/bin,
# both outside the stow tree.
#
# Requires: gcc, pkg-config, wayland-scanner, libwayland-client headers
# (apt: build-essential pkg-config libwayland-dev libwayland-bin)

set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${XDG_CACHE_HOME:-$HOME/.cache}/niri-tools/build"
bin_dir="$HOME/.local/bin"

need() {
    command -v "$1" >/dev/null || {
        printf 'niri tools: %s is not installed (%s)\n' "$1" "$2" >&2
        exit 1
    }
}

need gcc "apt install build-essential"
need pkg-config "apt install pkg-config"
need wayland-scanner "apt install libwayland-bin"
pkg-config --exists wayland-client || {
    echo "niri tools: wayland-client development files are missing (apt install libwayland-dev)" >&2
    exit 1
}

mkdir -p "$build_dir" "$bin_dir"

# wayland-scanner turns each protocol XML into a client header and the glue code
# that carries the interface tables. xdg-shell is here only because the
# layer-shell types table references xdg_popup; nothing links against it
# otherwise.
for proto in wlr-layer-shell-unstable-v1 xdg-shell; do
    wayland-scanner client-header "$src_dir/protocols/$proto.xml" \
        "$build_dir/$proto-client-protocol.h"
    wayland-scanner private-code "$src_dir/protocols/$proto.xml" \
        "$build_dir/$proto-protocol.c"
done

gcc -O2 -Wall -Wextra -o "$bin_dir/niri-cursor-pos" \
    "$src_dir/niri-cursor-pos.c" \
    "$build_dir/wlr-layer-shell-unstable-v1-protocol.c" \
    "$build_dir/xdg-shell-protocol.c" \
    -I "$build_dir" \
    $(pkg-config --cflags --libs wayland-client)

printf 'niri tools: built %s\n' "$bin_dir/niri-cursor-pos"
