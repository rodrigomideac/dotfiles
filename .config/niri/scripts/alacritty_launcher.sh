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

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

workspace="$(nt_focused_workspace_name)"
if [[ -n "$workspace" ]] && nt_is_task_workspace "$workspace"; then
    if worktree="$(nt_worktree_of_workspace "$workspace")"; then
        exec alacritty --working-directory="$worktree"
    fi
fi

whereami="$(cat /tmp/whereami 2>/dev/null || true)"
if [[ -n "$whereami" && -d "$whereami" ]]; then
    exec alacritty --working-directory="$whereami"
fi

exec alacritty
