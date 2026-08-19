#!/usr/bin/env bash
# niri-named-workspace.sh <up|down> [move]
#
# Move focus (or carry the focused column) to the next/previous *named* workspace
# on the focused output, skipping unnamed ones — including the always-empty
# workspace niri keeps at the bottom of every output.
#
# niri has no built-in action for this: focus-workspace-down/up step through every
# workspace, named or not. On DP-3, where every real workspace is a named task and
# the trailing empty one is not, that means every second keypress lands nowhere.
#
# Scoped to the focused output on purpose, so this walks task workspaces on DP-3
# and the three anchors on HDMI-A-1, and never jumps between screens. Wraps around
# at the ends; with a handful of named workspaces that is the useful behaviour.
#
# Bound to Mod+J / Mod+K, and with `move` to Mod+Ctrl+J / Mod+Ctrl+K.

set -uo pipefail

direction="${1:?usage: niri-named-workspace.sh <up|down> [move]}"
mode="${2:-focus}"

workspaces="$(niri msg -j workspaces)" || exit 1

output="$(jq -r 'first(.[] | select(.is_focused) | .output) // empty' <<<"$workspaces")"
current="$(jq -r 'first(.[] | select(.is_focused) | .idx) // empty' <<<"$workspaces")"
[[ -n "$output" && -n "$current" ]] || exit 0

mapfile -t named < <(jq -r --arg o "$output" '
    [ .[] | select(.output == $o and .name != null) ]
    | sort_by(.idx)[]
    | "\(.idx)\t\(.name)"' <<<"$workspaces")

(( ${#named[@]} )) || exit 0

target=""
case "$direction" in
    down)
        for entry in "${named[@]}"; do
            IFS=$'\t' read -r idx name <<<"$entry"
            if (( idx > current )); then
                target="$name"
                break
            fi
        done
        # Past the last named workspace: wrap to the first.
        [[ -z "$target" ]] && IFS=$'\t' read -r _ target <<<"${named[0]}"
        ;;
    up)
        for (( i = ${#named[@]} - 1; i >= 0; i-- )); do
            IFS=$'\t' read -r idx name <<<"${named[i]}"
            if (( idx < current )); then
                target="$name"
                break
            fi
        done
        # Above the first named workspace: wrap to the last.
        [[ -z "$target" ]] && IFS=$'\t' read -r _ target <<<"${named[-1]}"
        ;;
    *)
        exit 2
        ;;
esac

[[ -n "$target" ]] || exit 0

if [[ "$mode" == "move" ]]; then
    niri msg action move-column-to-workspace "$target" >/dev/null 2>&1
else
    niri msg action focus-workspace "$target" >/dev/null 2>&1
fi
