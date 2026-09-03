#!/usr/bin/env bash
# Move a floating window to the mouse pointer.
#
# niri has no pointer-relative placement: `default-floating-position` only takes
# the eight screen edges and corners, and the IPC has no cursor query at all.
# `niri-cursor-pos` (tools/niri-cursor-pos.c, built by `make tools`) supplies the
# missing half by asking Wayland directly, and this script does the arithmetic
# and the move.
#
#   niri-place-at-cursor.sh                 # the focused window
#   niri-place-at-cursor.sh --id 557        # a window by id — how the late
#                                           # window rules place Zoom's toasts
#   niri-place-at-cursor.sh --center        # centred on the pointer instead of
#                                           # hanging off it like a tooltip
#   niri-place-at-cursor.sh --id 557 --size 480,720   # size it is about to be
#
# By default the window's top-left corner lands just below and to the right of
# the pointer, so the pointer stays *outside* the window: focus-follows-mouse is
# on, and a window placed under the pointer would take focus the moment it
# appears. Near the right or bottom edge the window flips to the other side of
# the pointer, the way a context menu does.
#
# Coordinate spaces, since niri mixes two of them:
#   - `niri msg -j windows` reports tile_pos_in_workspace_view, relative to the
#     top-left of the *output*.
#   - `move-floating-window -x/-y` takes coordinates relative to the top-left of
#     the *working area* — the output minus whatever waybar and friends reserve.
# The offset between them is not queryable, so it is measured once per output
# (move to 0,0, read where that landed) and cached in $XDG_RUNTIME_DIR.

set -uo pipefail

OFFSET_X="${NIRI_PLACE_OFFSET_X:-16}"   # tooltip gap between pointer and window
OFFSET_Y="${NIRI_PLACE_OFFSET_Y:-16}"
MARGIN="${NIRI_PLACE_MARGIN:-8}"        # keep this much clear of the edges
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/niri-workarea"

# systemd user units do not always carry ~/.local/bin, where `make tools`
# installs the helper, so look there before falling back to PATH.
CURSOR_BIN="${NIRI_CURSOR_POS_BIN:-}"
if [[ -z "$CURSOR_BIN" ]]; then
    if [[ -x "$HOME/.local/bin/niri-cursor-pos" ]]; then
        CURSOR_BIN="$HOME/.local/bin/niri-cursor-pos"
    else
        CURSOR_BIN="niri-cursor-pos"
    fi
fi

id=""
center=0
recalibrate=0
size_w=""    # --size overrides, for a caller that just asked for a resize
size_h=""

die() {
    printf 'niri-place-at-cursor: %s\n' "$1" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --id) id="${2:-}"; shift 2 ;;
    --center) center=1; shift ;;
    --recalibrate) recalibrate=1; shift ;;
    --offset) OFFSET_X="${2%%,*}"; OFFSET_Y="${2##*,}"; shift 2 ;;
    # A resize is only reported once the client acks it, so a caller that has
    # just resized the window has to say how big it is about to be — otherwise
    # the edge clamping below works off the stale size. Either half may be "-".
    --size) size_w="${2%%,*}"; size_h="${2##*,}"; shift 2 ;;
    -h | --help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
    esac
done

command -v jq >/dev/null || die "jq is not installed"
command -v "$CURSOR_BIN" >/dev/null ||
    die "$CURSOR_BIN not found — build it with 'make tools' in the dotfiles repo"

if [[ -z "$id" ]]; then
    id="$(niri msg -j focused-window 2>/dev/null | jq -r '.id // empty')"
    [[ -n "$id" ]] || die "nothing is focused and no --id was given"
fi
[[ "$id" =~ ^[0-9]+$ ]] || die "--id must be a window id, got: $id"

# window_fields <id> -> "workspace_id x y width height is_floating"
window_fields() {
    niri msg -j windows 2>/dev/null | jq -r --argjson id "$1" '
        .[] | select(.id == $id)
        | [ .workspace_id,
            (.layout.tile_pos_in_workspace_view[0] | floor),
            (.layout.tile_pos_in_workspace_view[1] | floor),
            .layout.window_size[0],
            .layout.window_size[1],
            (if .is_floating then 1 else 0 end) ]
        | @tsv'
}

read -r ws _ _ w h floating < <(window_fields "$id")
[[ -n "${ws:-}" ]] || die "no window with id $id"

# A tiled window has no free position to set; float it first.
if [[ "$floating" == 0 ]]; then
    niri msg action move-window-to-floating --id "$id" >/dev/null 2>&1 ||
        die "could not float window $id"
    read -r ws _ _ w h floating < <(window_fields "$id")
    [[ -n "${ws:-}" ]] || die "window $id disappeared while being floated"
fi

[[ "$size_w" =~ ^[0-9]+$ ]] && w="$size_w"
[[ "$size_h" =~ ^[0-9]+$ ]] && h="$size_h"

read -r cx cy cursor_output < <("$CURSOR_BIN") ||
    die "could not read the pointer position"

window_output="$(niri msg -j workspaces 2>/dev/null |
    jq -r --argjson ws "$ws" '.[] | select(.id == $ws) | .output')"
[[ -n "$window_output" ]] || die "could not resolve the output of workspace $ws"

# Positions are per-output, so a window on the other monitor has to come across
# before any of the arithmetic below means anything.
if [[ "$window_output" != "$cursor_output" ]]; then
    niri msg action move-window-to-monitor "$cursor_output" --id "$id" >/dev/null 2>&1 ||
        die "could not move window $id to $cursor_output"
    read -r ws _ _ w h floating < <(window_fields "$id")
    [[ -n "${ws:-}" ]] || die "window $id disappeared while changing monitor"
fi

read -r out_w out_h < <(niri msg -j outputs 2>/dev/null |
    jq -r --arg o "$cursor_output" '.[$o].logical | "\(.width) \(.height)"')
[[ -n "${out_w:-}" && "$out_w" != "null" ]] || die "could not read the geometry of $cursor_output"

# The working-area origin in output coordinates: park the window at the origin
# of the move-floating-window space and see where it actually landed. Cached
# because it only changes when the bars do, and $XDG_RUNTIME_DIR is wiped at
# logout anyway.
cache="$CACHE_DIR/$cursor_output"
if [[ "$recalibrate" == 1 || ! -r "$cache" ]]; then
    niri msg action move-floating-window --id "$id" -x 0 -y 0 >/dev/null 2>&1
    read -r _ ox oy _ _ _ < <(window_fields "$id")
    [[ -n "${oy:-}" ]] || die "calibration failed: window $id vanished"
    mkdir -p "$CACHE_DIR" && printf '%s %s\n' "$ox" "$oy" >"$cache"
else
    read -r ox oy <"$cache"
fi

if [[ "$center" == 1 ]]; then
    tx=$((cx - w / 2))
    ty=$((cy - h / 2))
else
    # Tooltip placement, flipping to the other side of the pointer when the
    # window would otherwise run off the right or bottom edge.
    tx=$((cx + OFFSET_X))
    ty=$((cy + OFFSET_Y))
    ((tx + w > out_w - MARGIN)) && tx=$((cx - OFFSET_X - w))
    ((ty + h > out_h - MARGIN)) && ty=$((cy - OFFSET_Y - h))
fi

# Keep the whole window inside the working area. The low bound wins on an output
# too small for the window, which is the same thing niri would do anyway.
((tx > out_w - w - MARGIN)) && tx=$((out_w - w - MARGIN))
((ty > out_h - h - MARGIN)) && ty=$((out_h - h - MARGIN))
((tx < ox + MARGIN)) && tx=$((ox + MARGIN))
((ty < oy + MARGIN)) && ty=$((oy + MARGIN))

[[ -n "${NIRI_PLACE_DEBUG:-}" ]] && printf \
    'niri-place-at-cursor: id=%s size=%sx%s cursor=%s,%s on %s origin=%s,%s target=%s,%s\n' \
    "$id" "$w" "$h" "$cx" "$cy" "$cursor_output" "$ox" "$oy" "$tx" "$ty" >&2

niri msg action move-floating-window --id "$id" -x $((tx - ox)) -y $((ty - oy)) >/dev/null 2>&1 ||
    die "could not move window $id"
