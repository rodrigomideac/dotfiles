#!/usr/bin/env bash
# niri-named-workspace.sh <up|down> [focus|move] [output]
#
# Move focus (or carry the focused column) to the next/previous *named* workspace
# on an output, skipping unnamed ones — including the always-empty workspace niri
# keeps at the bottom of every output. The output defaults to the focused one;
# naming one explicitly cycles that output from anywhere.
#
# niri has no built-in action for this: focus-workspace-down/up step through every
# workspace, named or not. On DP-3, where every real workspace is a named task and
# the trailing empty one is not, that means every second keypress lands nowhere.
#
# Wraps around at the ends; with a handful of named workspaces that is the useful
# behaviour.
#
# Bound to Mod+J / Mod+K for the focused output — so it walks task workspaces on
# DP-3 and the three anchors on HDMI-A-1 without ever jumping between screens —
# and with `move` to Mod+Ctrl+J / Mod+Ctrl+K. Mod+Tab names the task output
# explicitly, so the task stack is reachable from either screen.

set -uo pipefail

direction="${1:?usage: niri-named-workspace.sh <up|down> [focus|move] [output]}"
mode="${2:-focus}"
output="${3:-}"

workspaces="$(niri msg -j workspaces)" || exit 1

focused_output="$(jq -r 'first(.[] | select(.is_focused) | .output) // empty' <<<"$workspaces")"
[[ -n "$output" ]] || output="$focused_output"
[[ -n "$output" ]] || exit 0

# Step from the workspace *active on the target output*, not from the focused
# one. They are the same workspace whenever the target is the focused output,
# and when it is not, the focused workspace's index says nothing about where to
# step from — it is a position on the other screen.
current="$(jq -r --arg o "$output" \
    'first(.[] | select(.output == $o and .is_active) | .idx) // empty' <<<"$workspaces")"
active_name="$(jq -r --arg o "$output" \
    'first(.[] | select(.output == $o and .is_active) | .name) // empty' <<<"$workspaces")"
[[ -n "$current" ]] || exit 0

# Arriving from the other screen: land on what the target output is already
# showing instead of stepping past it, so the first press never skips the
# workspace you left behind. Falls through when that workspace is unnamed — the
# trailing empty one — since there is nothing to land on.
if [[ "$mode" == "focus" && "$output" != "$focused_output" && -n "$active_name" ]]; then
    niri msg action focus-workspace "$active_name" >/dev/null 2>&1
    exit 0
fi

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
