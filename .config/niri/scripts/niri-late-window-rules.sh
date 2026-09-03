#!/usr/bin/env bash
# Late window rules: what config.kdl cannot express.
#
# Two kinds of rule live here — floating a window whose title only becomes
# matchable *after* it is mapped, and placing a window under the mouse pointer.
#
# niri evaluates the open-* and default-* window rule properties once, when the
# window opens. Firefox maps every window with the placeholder title "Mozilla
# Firefox" and sets the real one a moment later, so a `window-rule` matching on
# a Firefox title can never fire for those properties — confirmed on the event
# stream:
#
#     {"id":601,"app_id":"firefox_firefox","title":"Mozilla Firefox"}
#     {"id":601,"app_id":"firefox_firefox","title":"Licenses — Mozilla Firefox"}
#
# Title rules still work for the *dynamic* properties (opacity, block-out-from,
# borders), which niri re-evaluates on every title change, and they work at open
# time for toolkits that set the title before mapping — the jetbrains `win\d+`
# rule in config.kdl does. They do not work for open-floating on Firefox.
#
# So this watches the event stream and floats the window by id once its title
# arrives. Rules that *can* live in config.kdl belong there; this file is only
# for the ones that cannot.
#
# The other gap is placement. `default-floating-position` takes only the eight
# screen edges and corners, so no rule can put a window where the pointer is —
# every Zoom popup ("Zoom AI is on", "meeting bottombar popup", the menus) landed
# stacked in the top-left corner, half a screen from wherever you were working.
# The `cursor` placement below hands them to niri-place-at-cursor.sh, which asks
# niri-cursor-pos where the pointer is and moves the window there.
#
# Runs as niri-late-window-rules.service, bound to niri.service.
# Restart it after editing:  systemctl --user restart niri-late-window-rules

set -uo pipefail

# app-id regex <TAB> title regex <TAB> exclude title regex <TAB> width <TAB>
# height <TAB> placement
# Regexes are POSIX ERE (bash =~), not the Rust syntax config.kdl uses; "-" in
# the exclude column matches nothing back out.
# Width and height are logical pixels, or "-" to leave the size alone; a window
# smaller than its own minimum simply gets the minimum.
# Placement is "-" to leave the window where niri put it, or "cursor" to move it
# under the mouse pointer.
RULES=(
    # Bitwarden's popped-out vault. Matching on the app-id alone would float
    # every Firefox window, so the title is the only usable discriminator.
    $'firefox$\t^Extension: \\(Bitwarden Password Manager\\)\t-\t480\t720\t-'

    # Every Zoom popup goes under the pointer: the meeting-start toasts, the
    # bottom-bar popups, the menus, and whatever Zoom adds next. Enumerating
    # their titles was a losing game — each meeting turned up another one, and a
    # title this does not know about lands stacked in the top-left corner from
    # the catch-all rule in config.kdl.
    #
    # The exclusions are the windows that have a place of their own: the main
    # window (which is usually *tiled*, and would be dragged out of the layout
    # and floated by a placement), the screen-share control bar pinned to the
    # bottom, and the chat panel docked to the right.
    $'^(zoom|us\\.zoom\\.Zoom|Zoom Workplace)$\t.*\t^(Meeting|Meeting chat|as_toolbar)$| - Licensed account$\t-\t-\tcursor'
)

place_at_cursor="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/niri-place-at-cursor.sh"

declare -A applied=()   # window id -> already acted on, so a later title change
                        # does not re-float a window put back by hand

# Placement runs in the background: reading the pointer takes a moment while
# niri animates the window open, and the event stream must not stall behind it.
# The title is re-read first, because a catch-all rule matches on whatever title
# the window mapped with — and a window that renames itself a moment later (see
# the Firefox case above) must not be dragged to the pointer on the strength of
# a placeholder. A window that closed in the meantime simply drops out.
place_at_cursor_when_settled() {
    local id="$1" excl="$2" w="$3" h="$4" title
    sleep 0.15
    title="$(niri msg -j windows 2>/dev/null |
        jq -r --argjson id "$id" '.[] | select(.id == $id) | .title // ""')"
    [[ -n "$title" ]] || return
    [[ "$excl" != "-" && "$title" =~ $excl ]] && return
    "$place_at_cursor" --id "$id" --size "$w,$h"
}

apply_rules() {
    local id="$1" app="$2" title="$3" floating="$4"
    [[ -n "${applied[$id]:-}" ]] && return
    local app_re title_re excl_re w h place
    while IFS=$'\t' read -r app_re title_re excl_re w h place; do
        [[ -z "$app_re" ]] && continue
        [[ "$app" =~ $app_re ]] || continue
        [[ "$title" =~ $title_re ]] || continue
        [[ "$excl_re" != "-" && "$title" =~ $excl_re ]] && continue
        applied["$id"]=1
        [[ "$floating" == 1 ]] ||
            niri msg action move-window-to-floating --id "$id" >/dev/null 2>&1
        [[ "$w" != "-" ]] && niri msg action set-window-width --id "$id" "$w" >/dev/null 2>&1
        [[ "$h" != "-" ]] && niri msg action set-window-height --id "$id" "$h" >/dev/null 2>&1
        # In the background: reading the pointer takes a moment while niri
        # animates the window open, and the event stream must not stall behind
        # it. Short-lived windows may close first, which the script tolerates.
        # The size is handed over because niri still reports the old one until
        # the client acks a resize, and the placement needs it to keep the
        # window clear of the screen edges.
        if [[ "$place" == "cursor" ]]; then
            place_at_cursor_when_settled "$id" "$excl_re" "$w" "$h" &
        fi
        return
    done < <(printf '%s\n' "${RULES[@]}")
}

# The stream opens with a snapshot, so windows already up when this starts are
# considered too; after that every open and every title change comes through
# WindowOpenedOrChanged.
read_events() {
    jq --unbuffered -r '
        def row: ["w", (.id|tostring), .app_id // "", .title // "",
                  (if .is_floating then "1" else "0" end)];
        if has("WindowsChanged") then
            .WindowsChanged.windows[] | row
        elif has("WindowOpenedOrChanged") then
            .WindowOpenedOrChanged.window | row
        elif has("WindowClosed") then
            ["c", (.WindowClosed.id|tostring), "", "", ""]
        else empty end
        | @tsv'
}

while IFS=$'\t' read -r kind id app title floating; do
    case "$kind" in
    w) apply_rules "$id" "$app" "$title" "$floating" ;;
    c) unset 'applied[$id]' ;;
    esac
done < <(niri msg -j event-stream 2>/dev/null | read_events)

# The stream ended. If niri still answers, something went wrong and systemd
# should restart us; if it does not, the compositor is gone and so are we.
niri msg -j windows >/dev/null 2>&1 && exit 1
exit 0
