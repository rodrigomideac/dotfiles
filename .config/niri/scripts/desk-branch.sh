#!/usr/bin/env bash
# Feeds waybar's custom/desk-branch module (DP-3 only): the git branch checked
# out on the desk showing there.
#
# Replaces custom/task-slug, which printed the workspace name. With desks that
# is no longer worth a module — the name is `blue`, and niri/workspaces is back
# on the bar showing all five at once. What the name no longer tells you is what
# the desk is *for*, because a desk holds whatever you last checked out into it.
# So the bar shows the branch instead, and the colour says which desk it is.
#
# A plain exec on an interval rather than a long-lived reader of niri's event
# stream, which is how task-slug worked. The branch changes when you run `git
# checkout` inside a desk, and no compositor event fires for that — a follower
# would sit there showing the old branch until you cycled away and back. Polling
# catches both, at the cost of a git call every few seconds and up to one
# interval of lag when switching desks.

set -uo pipefail

# shellcheck source=/dev/null
source "$(dirname -- "$(readlink -f -- "$0")")/niri-desk-lib.sh"

name="$(desk_active_desk)"

if ! desk_is_desk "$name"; then
    jq -cn '{text: "", tooltip: ""}'
    exit 0
fi

branch="$(desk_branch "$name")" || branch=""
worktree="$(desk_worktree "$name")" || worktree=""

if [[ -n "$branch" ]]; then
    tooltip="$name — $worktree"$'\n'"$branch"
else
    tooltip="$name — $worktree"
fi

# The class is the desk name, so style.css can tint this the same colour as the
# workspace button next to it.
jq -cn --arg text "$branch" --arg tooltip "$tooltip" --arg class "$name" \
    '{text: $text, tooltip: $tooltip, class: $class}'
