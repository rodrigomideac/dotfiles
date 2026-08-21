#!/usr/bin/env bash
# Feeds waybar's custom/task-slug module (DP-3 only): the slug typed in
# niri-task-new.sh for the focused task workspace, resolved back from its
# worktree path since niri only ever stores the bare ticket key as the
# workspace name (see the "Workspace model" section of ../CLAUDE.md).
#
# Runs as a long-lived process reading niri's event stream, in the same style
# as custom/playerctl's `-F` follow mode: each print is one JSON line, and
# waybar treats a continuous stream of lines from a custom exec as live
# updates rather than re-running the command.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

nt_require_config

print_current() {
    local key path slug text
    key="$(niri msg -j workspaces 2>/dev/null \
        | jq -r --arg o "$TASK_OUTPUT" \
            'first(.[] | select(.output == $o and .is_focused)) | .name // empty')"
    text="$key"
    if [[ -n "$key" ]] && nt_is_ticket_key "$key"; then
        path="$(nt_resolve_worktree "$key" 2>/dev/null)" || path=""
        if [[ -n "$path" ]]; then
            slug="$(nt_slug_of_path "$path")"
            [[ -n "$slug" ]] && text="$slug"
        fi
    fi
    jq -cn --arg text "$text" '{text: $text, tooltip: $text}'
}

print_current
niri msg -j event-stream 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *WorkspaceActivated*|*WorkspacesChanged*) print_current ;;
    esac
done
