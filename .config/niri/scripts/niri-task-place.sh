#!/usr/bin/env bash
# niri-task-place.sh WORKSPACE APP_ID_REGEX BEFORE_IDS_CSV [TITLE_SUBSTRING]
#
# Corrective placement for a slow-starting application. Windows are normally
# spawned while their destination workspace is focused, so they land there by
# themselves; this only matters when focus moved away before the window mapped
# (IntelliJ takes seconds, and Chrome's first window at login does too).
#
# Candidate windows are identified by window-id set difference — never by the
# ticket key, because two worktrees can share one key (…-N and …-N-v2) and a
# key-based title match would pick whichever it found first.
#
# TITLE_SUBSTRING, when given, additionally requires the title to contain it. This
# exists because IntelliJ maps a splash/loading window with an *empty* title
# before its project window: without the filter the splash is matched first, the
# script exits, and the real project window arrives unplaced. The worktree
# directory name is unique per worktree and IntelliJ puts it at the front of the
# project window title, so it is the right discriminator.
#
# Gives up after two minutes.

set -uo pipefail

workspace="${1:?workspace name required}"
app_re="${2:?app-id regex required}"
before="${3:-}"
title_needle="${4:-}"

# First window matching the app-id whose id was not present before the spawn, and
# whose title contains the needle if one was given.
read -r -d '' NEW_WINDOW_JQ <<'JQ'
($before | split(",")) as $seen
| first(
    .[]
    | select((.app_id // "") | test($re))
    | select((.id | tostring) as $id | ($seen | index($id)) == null)
    | select($needle == "" or ((.title // "") | contains($needle)))
    | "\(.id)\t\(.workspace_id)"
  ) // empty
JQ

for _ in $(seq 1 120); do
    sleep 1

    # The workspace may have been released in the meantime; keep waiting rather
    # than moving the window somewhere arbitrary.
    target="$(niri msg -j workspaces 2>/dev/null \
        | jq -r --arg n "$workspace" 'first(.[] | select(.name == $n) | .id) // empty')"
    [[ -z "$target" ]] && continue

    found="$(niri msg -j windows 2>/dev/null | jq -r \
        --arg re "$app_re" --arg before "$before" --arg needle "$title_needle" \
        "$NEW_WINDOW_JQ")"
    [[ -z "$found" ]] && continue

    IFS=$'\t' read -r id ws <<<"$found"

    # Already in the right place: nothing to do, which is the common case.
    if [[ "$ws" != "$target" ]]; then
        niri msg action move-window-to-workspace "$workspace" \
            --window-id "$id" --focus false >/dev/null 2>&1
    fi
    exit 0
done
