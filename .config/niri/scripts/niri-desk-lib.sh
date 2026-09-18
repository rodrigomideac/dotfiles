#!/usr/bin/env bash
# Shared helpers for the fixed desk workspaces.
# Design and rationale: docs/adr/0003-fixed-colour-desks.md
#
# Sourced by alacritty_launcher.sh, startup.sh and desk-branch.sh. Not
# executable on its own.
#
# Replaces niri-task-lib.sh, which existed to create and track one workspace per
# Jira ticket. Nothing is created any more, so nearly all of it went: the Jira
# lookups, the slug and key parsing, the MRU worktree listing, the runtime
# key→worktree map, and the workspace claiming. What is left is the handful of
# questions a fixed set of desks still raises.
#
# Work-specific paths deliberately live outside this repository, in ~/.work-env,
# and are sourced rather than inherited because scripts spawned by niri get the
# compositor's environment, not an interactive shell's.

# shellcheck disable=SC1091
[[ -f "$HOME/.work-env" ]] && source "$HOME/.work-env"

DEV_ROOT="${CRAB_WORKTREES:-$HOME/dev}"

# The five desks, in the order they sit on the desk output — which, with no
# direct binds, is also the order Mod+Tab walks them in. crab is last so the
# four colours stay contiguous and cycling between them never passes through it.
DESKS=(blue red green yellow crab)

DESK_OUTPUT="${NIRI_DESK_OUTPUT:-DP-3}"
ANCHOR_OUTPUT="${NIRI_ANCHOR_OUTPUT:-HDMI-A-1}"
ANCHORS=(comm-tools slack personal)

BROWSER_CMD="${NIRI_DESK_BROWSER:-google-chrome-stable}"

desk_notify() { notify-send "niri-desk" "$1" >/dev/null 2>&1 || true; }

# Snapshot of every live window id, for niri-window-place.sh's set difference.
desk_window_ids() {
    niri msg -j windows 2>/dev/null | jq -r '.[].id' | sort -n
}

# True for a desk workspace, false for an anchor or an unnamed one. This used to
# ask whether the name parsed as a ticket worktree directory; now the set is
# fixed, so it is a plain membership test.
desk_is_desk() {
    local candidate="${1:-}" desk
    for desk in "${DESKS[@]}"; do
        [[ "$desk" == "$candidate" ]] && return 0
    done
    return 1
}

desk_focused_workspace() {
    niri msg -j workspaces 2>/dev/null \
        | jq -r 'first(.[] | select(.is_focused) | .name) // empty'
}

# The desk showing on the desk output, which is not the same question as which
# workspace has the keyboard. is_focused is global and goes false for every
# DP-3 workspace the moment focus moves to the other monitor — blanking a bar
# that is on DP-3 exactly when it is being read from across the desk. is_active
# is per output, so it keeps naming what is on screen there.
desk_active_desk() {
    niri msg -j workspaces 2>/dev/null \
        | jq -r --arg o "$DESK_OUTPUT" \
            'first(.[] | select(.output == $o and .is_active)) | .name // empty'
}

# The desk's directory. The workspace name is the directory name, so there is
# nothing to resolve — the check is only that it is really there.
desk_worktree() {
    local path="$DEV_ROOT/$1"
    [[ -d "$path" ]] || return 1
    printf '%s\n' "$path"
}

# The branch checked out on a desk, or a short sha when it is detached.
desk_branch() {
    local wt branch
    wt="$(desk_worktree "$1")" || return 1
    branch="$(git -C "$wt" branch --show-current 2>/dev/null)"
    [[ -n "$branch" ]] || branch="$(git -C "$wt" rev-parse --short HEAD 2>/dev/null)"
    [[ -n "$branch" ]] || return 1
    printf '%s\n' "$branch"
}

# Pin the anchors and the desks to indices 1..N on their own outputs, so both
# bars read left to right in the order declared above.
#
# Needed because declaration order in config.kdl is not honoured reliably: on a
# live config reload each newly declared workspace is inserted at the top, so
# fresh declarations come out reversed, and dock/undock scrambles them too (open
# upstream issue). Addressing by --reference acts on each workspace by name
# without having to focus it first, and the whole thing is idempotent, so it is
# safe to re-run at any time to repair the order.
#
# It matters more than it used to. Cycling is now the only way to reach a desk,
# so a scrambled order is not a cosmetic problem with the bar — it is Mod+Tab
# going somewhere other than where you expected.
desk_order() {
    local index name

    index=1
    for name in "${ANCHORS[@]}"; do
        niri msg action move-workspace-to-index "$index" --reference "$name" \
            >/dev/null 2>&1
        index=$(( index + 1 ))
    done

    index=1
    for name in "${DESKS[@]}"; do
        niri msg action move-workspace-to-index "$index" --reference "$name" \
            >/dev/null 2>&1
        index=$(( index + 1 ))
    done
}
