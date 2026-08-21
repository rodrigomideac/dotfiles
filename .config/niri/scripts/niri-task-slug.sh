#!/usr/bin/env bash
# Feeds waybar's custom/task-slug module (DP-3 only): the name of the task
# workspace active on that output, which is the worktree directory it belongs to
# (see the "Workspace model" section of ../CLAUDE.md). The module keeps its
# original id because that id is also a selector in waybar's style.css.
#
# There is nothing to resolve any more — before workspaces were named after
# their worktree this had to walk key → worktree → slug — so this needs none of
# the work configuration and runs on any machine.
#
# Runs as a long-lived process reading niri's event stream, in the same style
# as custom/playerctl's `-F` follow mode: each print is one JSON line, and
# waybar treats a continuous stream of lines from a custom exec as live
# updates rather than re-running the command.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

# is_active, not is_focused: the module sits on the task output's own bar, and
# is_focused is global — it is false for every DP-3 workspace whenever the
# keyboard is on the other monitor, which would blank the bar exactly when it is
# being read from across the desk. is_active is per output.
print_current() {
    local name tooltip
    name="$(niri msg -j workspaces 2>/dev/null \
        | jq -r --arg o "$TASK_OUTPUT" \
            'first(.[] | select(.output == $o and .is_active)) | .name // empty')"
    tooltip="$name"
    [[ -n "$name" && -d "$DEV_ROOT/$name" ]] && tooltip="$DEV_ROOT/$name"
    jq -cn --arg text "$name" --arg tooltip "$tooltip" \
        '{text: $text, tooltip: $tooltip}'
}

print_current
niri msg -j event-stream 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *WorkspaceActivated*|*WorkspacesChanged*) print_current ;;
    esac
done
