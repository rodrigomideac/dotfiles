#!/usr/bin/env bash
# Open a terminal (Mod+Return), preferring the worktree of the focused task
# workspace.
#
# The old behaviour was to always use /tmp/whereami, a single file overwritten by
# every shell prompt. With more than one worktree open that opens a terminal in
# whichever worktree most recently drew a prompt, not the one on screen. The
# workspace name is authoritative and is also what the bar shows — it is the
# worktree's directory name — so it wins; /tmp/whereami remains the fallback
# everywhere else.

set -uo pipefail

if [[ -n "${1:-}" ]]; then
    exec alacritty -e "$1"
fi

# shellcheck source=/dev/null
source "$(dirname -- "$(readlink -f -- "$0")")/niri-desk-lib.sh"

# The title is set to the desk name because niri cannot colour a workspace:
# window rules match on app-id and title only, there is no at-workspace (checked
# against niri 26.04), so a title the desk owns is the only handle a per-desk
# focus-ring rule has.
#
# dynamic_title is turned off with it, or the title would not survive: tmux and
# the shell rewrite it through an escape sequence within a second of the window
# mapping, which is why a terminal on a worktree currently reads "dev". The cost
# is that the window title stops tracking the running program — tmux's own status
# line already says that, and niri only shows the title in the overview.
workspace="$(desk_focused_workspace)"
if desk_is_desk "$workspace"; then
    if worktree="$(desk_worktree "$workspace")"; then
        exec alacritty \
            --title "$workspace" \
            -o window.dynamic_title=false \
            --working-directory="$worktree"
    fi
fi

whereami="$(cat /tmp/whereami 2>/dev/null || true)"
if [[ -n "$whereami" && -d "$whereami" ]]; then
    exec alacritty --working-directory="$whereami"
fi

exec alacritty
