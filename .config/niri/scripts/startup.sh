#!/usr/bin/env bash
#
# Niri startup: bring up the anchor workspaces and put both outputs in order.
#
# Nothing here restores desks: all five are declared in config.kdl, so they come
# back on their own and outlive a reboot. That is new — they used to be created
# on demand per ticket and were deliberately not restored (see
# docs/adr/0003-fixed-colour-desks.md, superseding 0001).
#
# The anchors are likewise declared in config.kdl with open-on-output, and
# window rules route Slack, Firefox and the Outlook PWA, so this script only has
# to launch things — no focus-monitor dance. Chrome is the exception: its main
# window shares app-id "google-chrome" with every per-task browser, so it cannot
# be routed by rule and is placed explicitly instead.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "$0")")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/niri-desk-lib.sh"

# Wait for niri to be fully initialized.
sleep 0.2

# Clipboard history via cliphist (picker bound to Mod+Ctrl+V).
# wl-clip-persist intentionally not used: it races niri's screenshot data
# source and clobbers the image clipboard with stale text content.
pgrep -f "wl-paste.*cliphist store" >/dev/null || {
    wl-paste --type text  --watch cliphist store &
    wl-paste --type image --watch cliphist store &
}

# Everything is declared already, but declaration order is not dependable, so
# pin both outputs: comm-tools/slack/personal on the anchor output, and the five
# desks on the desk output. The desks matter most — with no direct binds, their
# order *is* the navigation, so a scrambled one sends Mod+Tab somewhere you did
# not mean to go. Rebind on Mod+Shift+T to repair it after a dock/undock.
desk_order

# --- routed by window rule; workspace assignment needs no help here ----------
setsid slack                                    >/dev/null 2>&1 &
setsid firefox                                  >/dev/null 2>&1 &
setsid "$BROWSER_CMD" --profile-directory=Default \
    --app-id=eoficlgicibekocmfdomjbfnjmehnhcd   >/dev/null 2>&1 &   # Outlook PWA

# --- placed explicitly ------------------------------------------------------
# The internal PWA's id is not committed to this repository, so it gets no
# window rule either; it is launched and placed the same way Chrome is.
if [[ -n "${NIRI_TASK_COMM_PWA_ID:-}" ]]; then
    before="$(desk_window_ids | paste -sd,)"
    setsid "$BROWSER_CMD" --profile-directory=Default \
        --app-id="$NIRI_TASK_COMM_PWA_ID" >/dev/null 2>&1 &
    setsid "$SCRIPT_DIR/niri-window-place.sh" "comm-tools" \
        "^chrome-${NIRI_TASK_COMM_PWA_ID}-" "$before" >/dev/null 2>&1 &
fi

# Chrome's ordinary window (Jira board and everything else): focus comm-tools so
# it lands there natively, and place it by window id in case the first cold start
# outlives that focus.
niri msg action focus-workspace "comm-tools" >/dev/null 2>&1
before="$(desk_window_ids | paste -sd,)"
setsid "$BROWSER_CMD" >/dev/null 2>&1 &
setsid "$SCRIPT_DIR/niri-window-place.sh" "comm-tools" '^google-chrome$' "$before" \
    >/dev/null 2>&1 &

# End on the desk output, ready for Mod+Tab.
niri msg action focus-monitor "$DESK_OUTPUT" >/dev/null 2>&1
