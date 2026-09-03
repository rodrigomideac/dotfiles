#!/usr/bin/env bash
# Drop a task workspace's name once its last window is gone, so niri reaps the
# workspace itself.
#
# niri keeps a *named* workspace alive while it is empty — that is the whole
# point of naming one, and it is exactly right for the three anchors declared in
# config.kdl. It is wrong for task workspaces: closing a ticket's windows is how
# a task ends, and the leftover name goes on appearing in Mod+Tab, Mod+J and the
# overview as though the work were still open. There is no niri option for this;
# unset-workspace-name is the only lever, and Mod+Ctrl+T is it by hand.
#
# Only task workspaces are candidates. nt_is_task_workspace is true exactly for
# names that parse as a ticket worktree directory, so the anchors — and any
# workspace named for some other reason — are never touched.
#
# Two delays, because an empty task workspace means two different things.
# One that has *held* a window and lost it is a finished task: it settles for a
# few seconds — long enough for a window in transit between workspaces, which
# empties the old one for an instant — and then goes. One this process has never
# seen hold a window is more likely still being built: nt_open_task names the
# workspace before spawning the browser, terminal and IDE into it, and reaping in
# that gap would pull the name out from under the placer. Those get the long
# grace, which only ever applies to workspaces already present when this started,
# since anything created afterwards is watched as it fills.
#
# Runs as niri-workspace-reaper.service, bound to niri.service, so it restarts if
# it dies and stops when the compositor does. Restart it after editing this file.
# It is silent; `niri msg -j workspaces` after closing a task's windows is what
# tells the story.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

SETTLE="${NIRI_TASK_REAP_SETTLE:-3}"     # emptied under our eyes
GRACE="${NIRI_TASK_REAP_GRACE:-60}"      # already empty when we started

# Keyed by workspace name, which niri keeps unique among named workspaces. Names
# are also what unset-workspace-name takes, so no id bookkeeping is needed; an
# entry is dropped as soon as its name leaves the named set, which keeps a reaped
# name from carrying its history into the next workspace that reuses it.
declare -A seen_windows=()   # name -> has held a window at least once
declare -A empty_since=()    # name -> when it last went empty

sweep() {
    local name output count patience now="$EPOCHSECONDS"
    local -A live=()

    while IFS=$'\t' read -r name output count; do
        live["$name"]=1
        nt_is_task_workspace "$name" || continue

        if (( count > 0 )); then
            seen_windows["$name"]=1
            unset 'empty_since[$name]'
            continue
        fi

        [[ -n "${seen_windows[$name]:-}" ]] && patience="$SETTLE" || patience="$GRACE"

        if [[ -z "${empty_since[$name]:-}" ]]; then
            empty_since["$name"]="$now"
        elif (( now - empty_since["$name"] >= patience )); then
            niri msg action unset-workspace-name "$name" >/dev/null 2>&1
            unset 'empty_since[$name]' 'seen_windows[$name]'
        fi
    done < <(nt_named_workspaces 2>/dev/null)

    for name in "${!seen_windows[@]}"; do
        [[ -n "${live[$name]:-}" ]] || unset 'seen_windows[$name]'
    done
    for name in "${!empty_since[@]}"; do
        [[ -n "${live[$name]:-}" ]] || unset 'empty_since[$name]'
    done
}

# The event stream gets its own descriptor so the niri msg calls inside sweep
# cannot eat from it.
exec 3< <(niri msg -j event-stream 2>/dev/null)

sweep

while :; do
    line=""
    if (( ${#empty_since[@]} )); then
        # A settle timer is running and nothing else may happen before it
        # expires, so stop waiting for events long enough to re-check.
        read -r -u 3 -t 1 line
    else
        read -r -u 3 line
    fi
    rc=$?

    # rc above 128 is the read timeout; anything else non-zero with nothing read
    # is end of stream.
    (( rc != 0 && rc <= 128 && ${#line} == 0 )) && break

    case "$line" in
        # Window events change the counts; workspace events change the set.
        # Focus and layout events are the noisy ones and change neither.
        ""|*'"WindowClosed"'*|*'"WindowOpenedOrChanged"'* \
          |*'"WindowsChanged"'*|*'"WorkspacesChanged"'*) sweep ;;
    esac
done

# The stream ended. Which of the two reasons it was decides the exit status, and
# the unit restarts on failure only: a compositor that is still answering means
# the stream dropped under us and a fresh one is worth having, while a compositor
# that is gone means BindsTo is already stopping this unit — exiting clean keeps
# systemd from racing a pointless restart against that.
niri msg -j workspaces >/dev/null 2>&1 && exit 1
exit 0
