#!/usr/bin/env bash
# Re-pin the anchors and desks to their declared order on both outputs
# (Mod+Shift+T).
#
# Declaration order in config.kdl is not honoured on a live config reload — each
# newly declared workspace is inserted at the top, so a fresh set comes out
# reversed — and docking or undocking scrambles it too. startup.sh does this at
# login; this is the same call, bound to a key, for when it drifts in between.

set -uo pipefail

# shellcheck source=/dev/null
source "$(dirname -- "$(readlink -f -- "$0")")/niri-desk-lib.sh"

desk_order
