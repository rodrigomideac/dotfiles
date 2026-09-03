#!/usr/bin/env bash
# Dump what niri knows about windows, so a window rule can be written for one.
#
# A window rule matches on app-id and title, and both are only discoverable at
# runtime through `niri msg`. That is easy for a window you can focus and
# impossible for the ones that most need a rule: splash screens, menus and
# toolbars that vanish the moment focus moves, or that never take focus at all.
# Hence two modes, bound to Mod+F1 and Mod+F2 in config.kdl:
#
#   focused        what is focused right now, plus every other open window
#   watch [secs]   listen to the event stream for a few seconds and report the
#                  windows that appear in that window of time — press the bind,
#                  then do the thing that makes the popup show up
#
# Both write a Markdown report to ~/Documents/niri-windows/ containing a
# ready-to-paste window-rule block per window, with the app-id and title already
# regex-escaped, and fire a notification with the path.
#
# Requires: niri, jq, notify-send.

set -uo pipefail

MODE="${1:-focused}"
SECS="${2:-3}"
OUT_DIR="${NIRI_WINDOW_INSPECT_DIR:-$HOME/Documents/niri-windows}"

notify() { notify-send -t "${2:-6000}" "niri window inspect" "$1" >/dev/null 2>&1 || true; }

die() {
    notify "$1" 8000
    printf '%s\n' "$1" >&2
    exit 1
}

command -v jq >/dev/null || die "jq is not installed"

# The event stream reports workspaces by id only; names and outputs come from a
# separate query, taken once at report time.
workspaces="$(niri msg -j workspaces 2>/dev/null)" || die "cannot reach niri (is NIRI_SOCKET set?)"

render() {
    # $1 mode line, $2 sections as a JSON array of {heading, style, windows|ids, note}
    jq -nr \
        --argjson workspaces "$workspaces" \
        --argjson sections "$1" \
        --arg when "$(date '+%Y-%m-%d %H:%M:%S')" \
        --arg subtitle "$2" '
        # Escape a literal string for use inside a niri r#"..."# regex.
        def esc: gsub("(?<c>[\\[\\].*^$(){}?+|\\\\])"; "\\\(.c)");
        # Keep a value from breaking out of a Markdown table cell.
        def cell: (. // "") | tostring | gsub("\\|"; "\\|") | gsub("\n"; " ");

        def ws_label($id):
            ([$workspaces[] | select(.id == $id)] | first) as $w
            | if $w == null then "\($id)"
              else "\($id)"
                   + (if $w.name then " (`\($w.name)`)" else "" end)
                   + " on \($w.output)"
              end;

        def size:
            (.layout.window_size // [])
            | if length == 2 then "\(.[0])×\(.[1])" else "-" end;

        def rule_block:
            (.app_id // "" | esc) as $a | (.open_title // .title // "" | esc) as $t |
            "```kdl\nwindow-rule {\n"
            + "    match app-id=r#\"^\($a)$\"#\n"
            + "    // narrower, if the app-id alone is too broad:\n"
            + "    // match app-id=r#\"^\($a)$\"# title=r#\"^\($t)$\"#\n"
            + "    open-floating true\n}\n```\n";

        def detail($n):
            "### \($n). `\(.app_id // "?" | cell)` — \(.title // "?" | cell)\n\n"
            + "| field | value |\n| --- | --- |\n"
            + "| app-id | `\(.app_id // "" | cell)` |\n"
            + "| title | `\(.title // "" | cell)` |\n"
            + "| id | \(.id) |\n"
            + "| pid | \(.pid // "-") |\n"
            + "| workspace | \(ws_label(.workspace_id)) |\n"
            + "| floating | \(.is_floating) |\n"
            + "| size | \(size) |\n"
            + (if (.open_title != null and .open_title != .title)
               then "| title at open | `\(.open_title | cell)` |\n" else "" end)
            + "\n"
            + (if (.open_title != null and .open_title != .title)
               then "> **The title arrived after the window was mapped.** niri evaluates the\n"
                    + "> `open-*` and `default-*` properties once, at map time, so a title rule\n"
                    + "> only fires if it matches the title-at-open above. Firefox maps every\n"
                    + "> window as `Mozilla Firefox`, which no useful rule can match — those\n"
                    + "> windows have to go in `scripts/niri-late-window-rules.sh` instead.\n\n"
               else "" end)
            + rule_block;

        def compact:
            if length == 0 then "_none_\n"
            else "| app-id | title | id | floating | workspace |\n| --- | --- | --- | --- | --- |\n"
                 + (map("| `\(.app_id | cell)` | \(.title | cell) | \(.id) | \(.is_floating) | \(ws_label(.workspace_id)) |")
                    | join("\n"))
                 + "\n"
            end;

        def section:
            "## \(.heading)\n\n"
            + (if .note then .note + "\n\n" else "" end)
            + (if .style == "detail" then
                   if (.windows | length) == 0 then "_none_\n"
                   # $n is bound outside detail on purpose: a jq function
                   # argument is a closure evaluated where it is *used*, so
                   # detail(.key + 1) would look for .key on the window and
                   # number every entry 1.
                   else [.windows | to_entries[] | .key as $n | .value | detail($n + 1)] | join("\n")
                   end
               elif .style == "ids" then
                   if (.ids | length) == 0 then "_none_\n"
                   else "`" + (.ids | map(tostring) | join("`, `")) + "`\n"
                   end
               else (.windows | compact)
               end);

        "# niri windows — \($when)\n\n"
        + $subtitle + "\n\n"
        + ([$sections[] | section] | join("\n"))
        # Only the windows reported in full, so the dump stays greppable for the
        # fields this report does not render.
        + "\n---\n\n<details>\n<summary>Raw JSON</summary>\n\n```json\n"
        + ([$sections[] | select(.style == "detail") | .windows[]] | tojson)
        + "\n```\n\n</details>\n"
    '
}

write_report() {
    mkdir -p "$OUT_DIR" || die "cannot create $OUT_DIR"
    local out="$OUT_DIR/$(date +%Y%m%d-%H%M%S)-windows.md"
    render "$1" "$2" >"$out" || die "failed to render the report"
    printf '%s\n' "$out"
}

case "$MODE" in
focused)
    focused="$(niri msg -j focused-window 2>/dev/null)"
    [[ -z "$focused" || "$focused" == "null" ]] && focused="null"
    all="$(niri msg -j windows 2>/dev/null)" || die "cannot list windows"

    sections="$(jq -nc --argjson f "$focused" --argjson all "$all" '
        [ { heading: "Focused window", style: "detail",
            windows: (if $f == null then [] else [$f] end),
            note: (if $f == null then "Nothing was focused when this ran." else null end) },
          { heading: "All open windows (\($all | length))", style: "compact",
            windows: ($all | sort_by(.app_id, .title)) } ]')"

    label="$(jq -r 'if . == null then "nothing focused" else "\(.app_id) — \(.title)" end' <<<"$focused")"
    out="$(write_report "$sections" "Snapshot of the focused window and everything else open.")" || exit 1
    notify "$label
→ ${out/#$HOME/\~}"
    ;;

watch)
    [[ "$SECS" =~ ^[0-9]+$ ]] || die "watch duration must be a whole number of seconds, got: $SECS"
    notify "Watching for $SECS s — open the window now…" "$((SECS * 1000))"

    stream="$(mktemp)" || die "cannot create a temp file"
    trap 'rm -f "$stream"' EXIT
    # The stream opens with a full snapshot (WindowsChanged) and then reports
    # each window as it opens or changes; timeout ends it, so a non-zero exit
    # here is the normal path.
    timeout "$SECS" niri msg -j event-stream >"$stream" 2>/dev/null
    [[ -s "$stream" ]] || die "the event stream produced nothing — is niri running?"

    # Refresh workspace names: the interesting popup may have made its own.
    workspaces="$(niri msg -j workspaces 2>/dev/null)"

    sections="$(jq -sc '
        ([.[] | select(has("WindowsChanged")) | .WindowsChanged.windows[]] | unique_by(.id)) as $base
        | ($base | map(.id)) as $known
        # Last event per window wins, so a title settled after mapping is the one
        # reported — but the first is kept as open_title, because that is what a
        # window rule actually sees.
        | ([.[] | select(has("WindowOpenedOrChanged")) | .WindowOpenedOrChanged.window]
           | group_by(.id) | map(.[-1] + {open_title: .[0].title})) as $seen
        | [.[] | select(has("WindowClosed")) | .WindowClosed.id] as $closed
        | ($seen | map(select(.id as $i | $known | index($i) | not))) as $new
        | ($seen | map(select(.id as $i | $known | index($i)))) as $touched
        | [ { heading: "New windows (\($new | length))", style: "detail",
              windows: ($new | sort_by(.app_id, .title)),
              note: ($closed as $c
                     | ($new | map(select(.id as $i | $c | index($i))) | length) as $gone
                     | if $gone > 0 then "\($gone) of these had already closed again by the end of the watch." else null end) },
            { heading: "Windows that changed (\($touched | length))", style: "compact",
              windows: ($touched | sort_by(.app_id, .title)),
              note: "Already open when the watch started — usually just a title change." },
            { heading: "Closed during the watch", style: "ids", ids: ($closed | unique) },
            { heading: "Baseline: already open (\($base | length))", style: "compact",
              windows: ($base | sort_by(.app_id, .title)) } ]' "$stream")"

    [[ -n "$sections" ]] || die "could not parse the event stream"
    count="$(jq -r '.[0].windows | length' <<<"$sections")"
    out="$(write_report "$sections" "Watched the event stream for ${SECS} s.")" || exit 1
    notify "$count new window(s) in ${SECS}s
→ ${out/#$HOME/\~}"
    ;;

*)
    die "unknown mode: $MODE (expected: focused | watch [seconds])"
    ;;
esac
