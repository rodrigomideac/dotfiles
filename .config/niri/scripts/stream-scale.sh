#!/bin/bash

# Raise niri's output scale so the desktop stays readable at the far end of a
# Moonlight session.
#
# The desk monitor is 1920x1080 across 24"; the same frame on a 13" laptop
# panel is a little over half the physical size, which is what makes the text
# unreadable. Scale is the only knob that fixes that for free: it leaves the
# output *mode* alone, so the framebuffer wlr-screencopy hands to Sunshine is
# still 1920x1080 and the stream keeps every pixel it had. Lowering the mode
# instead would buy the same glyph size by throwing away detail everywhere.
#
# Fractional steps are safe here because every client on this desktop is a
# native Wayland one; nothing goes through xwayland-satellite to be upscaled.

set -euo pipefail

STEPS=(1 1.25 1.5 1.75 2)
DEFAULT_SCALE="${STREAM_SCALE:-1.5}"
SUNSHINE_CONF="$HOME/.config/sunshine/sunshine.conf"

# Sunshine's user service keeps the NIRI_SOCKET it inherited when it started,
# which goes stale the moment niri is restarted under it.
if [[ ! -S "${NIRI_SOCKET:-}" ]]; then
    socket=$(ls -t "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/niri.wayland-*.sock 2>/dev/null | head -1) || true
    [[ -n "${socket:-}" ]] && export NIRI_SOCKET="$socket"
fi

resolve_output() {
    if [[ -n "${STREAM_SCALE_OUTPUT:-}" ]]; then
        echo "$STREAM_SCALE_OUTPUT"
        return
    fi

    # Whatever Sunshine was told to capture is, by definition, the screen being
    # looked at from the other end.
    local configured
    configured=$(sed -n 's/^output_name *= *//p' "$SUNSHINE_CONF" 2>/dev/null | tail -1)
    if [[ -n "$configured" ]]; then
        echo "$configured"
        return
    fi

    local enabled
    mapfile -t enabled < <(niri msg -j outputs | jq -r 'to_entries[] | select(.value.logical) | .key')
    if [[ ${#enabled[@]} -eq 1 ]]; then
        echo "${enabled[0]}"
        return
    fi

    niri msg -j focused-output | jq -r '.name'
}

current_scale() {
    niri msg -j outputs | jq -r --arg o "$1" '.[$o].logical.scale // empty'
}

nearest_step() {
    printf '%s\n' "${STEPS[@]}" | awk -v cur="$1" '
        { diff = $1 - cur; if (diff < 0) diff = -diff }
        NR == 1 || diff < best { best = diff; idx = NR - 1 }
        END { print idx }'
}

apply() {
    local output=$1 scale=$2
    niri msg output "$output" scale "$scale" > /dev/null
    notify-send -t 1500 -h "string:x-canonical-private-synchronous:stream-scale" \
        "Desktop scale" "$output at ${scale}x" 2> /dev/null || true
}

usage() {
    cat >&2 <<'USAGE'
usage: stream-scale [on [SCALE] | off | toggle | up | down | status]

  on [SCALE]  scale the streamed output up (default $STREAM_SCALE, or 1.5)
  off         back to 1x
  toggle      between 1x and the default scale
  up | down   one step along 1 / 1.25 / 1.5 / 1.75 / 2
  status      print the output being driven and its current scale

The output is $STREAM_SCALE_OUTPUT, else Sunshine's output_name, else the only
enabled output, else the focused one.
USAGE
}

output=$(resolve_output)
if [[ -z "$output" || "$output" == "null" ]]; then
    echo "stream-scale: could not work out which output to scale" >&2
    exit 1
fi

case "${1:-toggle}" in
    on)
        apply "$output" "${2:-$DEFAULT_SCALE}"
        ;;
    off)
        apply "$output" 1
        ;;
    toggle)
        if [[ $(awk -v c="$(current_scale "$output")" 'BEGIN { print (c > 1.01) }') == 1 ]]; then
            apply "$output" 1
        else
            apply "$output" "$DEFAULT_SCALE"
        fi
        ;;
    up|down)
        index=$(nearest_step "$(current_scale "$output")")
        if [[ "$1" == "up" ]] && (( index < ${#STEPS[@]} - 1 )); then
            index=$(( index + 1 ))
        elif [[ "$1" == "down" ]] && (( index > 0 )); then
            index=$(( index - 1 ))
        fi
        apply "$output" "${STEPS[$index]}"
        ;;
    status)
        printf '%s %sx\n' "$output" "$(current_scale "$output")"
        ;;
    *)
        usage
        exit 1
        ;;
esac
