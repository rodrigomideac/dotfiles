#!/usr/bin/env bash
#
# Niri startup: bring up the three anchor workspaces on the anchor output.
#
# Task workspaces are deliberately NOT restored — see
# docs/adr/0001-niri-task-workspace-workflow.md. Restoring them would either
# cold-start several IDEs at login or leave empty named workspaces on the bar
# that look like live work. Resuming a ticket is Mod+T, Enter.
#
# The anchors themselves are declared in config.kdl with open-on-output, and
# window rules route Slack, Firefox and the Outlook PWA, so this script only has
# to launch things — no focus-monitor dance. Chrome is the exception: its main
# window shares app-id "google-chrome" with every per-task browser, so it cannot
# be routed by rule and is placed explicitly instead.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"
source "$SCRIPT_DIR/niri-task-lib.sh"

# Wait for niri to be fully initialized.
sleep 0.2

# Clipboard history via cliphist (picker bound to Mod+Ctrl+V).
# wl-clip-persist intentionally not used: it races niri's screenshot data
# source and clobbers the image clipboard with stale text content.
pgrep -f "wl-paste.*cliphist store" >/dev/null || {
    wl-paste --type text  --watch cliphist store &
    wl-paste --type image --watch cliphist store &
}

# The anchors exist already (declared in config.kdl) but their order is not
# dependable, so pin it: comm-tools, slack, personal — Mod+Q, Mod+W, Mod+E.
nt_order_anchors

# --- routed by window rule; workspace assignment needs no help here ----------
setsid slack                                    >/dev/null 2>&1 &
setsid firefox                                  >/dev/null 2>&1 &
setsid "$BROWSER_CMD" --profile-directory=Default \
    --app-id=eoficlgicibekocmfdomjbfnjmehnhcd   >/dev/null 2>&1 &   # Outlook PWA

# --- placed explicitly ------------------------------------------------------
# The internal PWA's id is not committed to this repository, so it gets no
# window rule either; it is launched and placed the same way Chrome is.
if [[ -n "${NIRI_TASK_COMM_PWA_ID:-}" ]]; then
    before="$(nt_window_ids | paste -sd,)"
    setsid "$BROWSER_CMD" --profile-directory=Default \
        --app-id="$NIRI_TASK_COMM_PWA_ID" >/dev/null 2>&1 &
    setsid "$SCRIPT_DIR/niri-task-place.sh" "comm-tools" \
        "^chrome-${NIRI_TASK_COMM_PWA_ID}-" "$before" >/dev/null 2>&1 &
fi

# Chrome's ordinary window (Jira board and everything else): focus comm-tools so
# it lands there natively, and place it by window id in case the first cold start
# outlives that focus.
niri msg action focus-workspace "comm-tools" >/dev/null 2>&1
before="$(nt_window_ids | paste -sd,)"
setsid "$BROWSER_CMD" >/dev/null 2>&1 &
setsid "$SCRIPT_DIR/niri-task-place.sh" "comm-tools" '^google-chrome$' "$before" \
    >/dev/null 2>&1 &

# Warm the Jira cache so the first Mod+T of the day is already annotated.
nt_jira_refresh_async

# End on the work output, ready for Mod+T.
niri msg action focus-monitor "$TASK_OUTPUT" >/dev/null 2>&1
