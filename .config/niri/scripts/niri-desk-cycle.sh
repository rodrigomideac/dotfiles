#!/usr/bin/env bash
# niri-desk-cycle.sh <next|prev>
#
# Cycle focus through the five fixed desks, in DESKS order, wrapping at both
# ends. Bound to Mod+Tab / Mod+Shift+Tab.
#
# Mod+Tab used to call niri-named-workspace.sh with the desk output named, which
# walks the *named workspaces of an output*. That set is the five desks only
# while the anchor monitor is plugged in: undocked, niri migrates the anchors
# onto the remaining output and Mod+Tab starts cycling through Slack and the
# browser alongside the desks. The desks are a fixed, declared list, so cycling
# reads the list rather than inferring it from which screen a workspace sits on.
#
# Empty desks are cycled too. The five exist from login whether or not anything
# is open in them, and skipping the bare ones left a desk unreachable by
# keyboard the moment its last window closed. Mod+J / Mod+K keep the occupancy
# filter, so the "only stop where there is work" walk is still a keypress away.

set -uo pipefail

# shellcheck source=/dev/null
source "$HOME/.config/niri/scripts/niri-desk-lib.sh"

direction="${1:?usage: niri-desk-cycle.sh <next|prev>}"

# Landing desk, for coming back from an anchor. While the anchor monitor is
# plugged in the desk output's is_active workspace answers this for free; with
# one screen it is an anchor, so the last desk has to be remembered.
state_file="${XDG_RUNTIME_DIR:-/tmp}/niri-desk-cycle"

workspaces="$(niri msg -j workspaces)" || exit 1
mapfile -t live < <(jq -r '.[] | select(.name != null) | .name' <<<"$workspaces")

# DESKS order, not niri's: a desk missing from the config is dropped rather than
# aborting the cycle, and the remaining ones still walk in the declared order.
desks=()
for desk in "${DESKS[@]}"; do
    for name in "${live[@]}"; do
        [[ "$name" == "$desk" ]] && { desks+=("$desk"); break; }
    done
done
(( ${#desks[@]} )) || exit 0

index_of() {
    local needle="$1" i
    for i in "${!desks[@]}"; do
        [[ "${desks[i]}" == "$needle" ]] && { printf '%s\n' "$i"; return 0; }
    done
    return 1
}

focused="$(jq -r 'first(.[] | select(.is_focused) | .name) // empty' <<<"$workspaces")"

target=""
if current="$(index_of "$focused")"; then
    case "$direction" in
        next) target="${desks[(current + 1) % ${#desks[@]}]}" ;;
        prev) target="${desks[(current - 1 + ${#desks[@]}) % ${#desks[@]}]}" ;;
        *)    exit 2 ;;
    esac
else
    # Arriving from an anchor: land on the desk left behind instead of stepping
    # past it, so the first press after Slack never costs a desk.
    showing="$(desk_active_desk)"
    if ! index_of "$showing" >/dev/null; then
        showing="$(cat "$state_file" 2>/dev/null)"
        index_of "$showing" >/dev/null || showing=""
    fi
    if [[ -n "$showing" ]]; then
        target="$showing"
    else
        case "$direction" in
            next) target="${desks[0]}" ;;
            prev) target="${desks[-1]}" ;;
            *)    exit 2 ;;
        esac
    fi
fi

niri msg action focus-workspace "$target" >/dev/null 2>&1 \
    && printf '%s\n' "$target" >"$state_file" 2>/dev/null
