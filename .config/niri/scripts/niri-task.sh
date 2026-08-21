#!/usr/bin/env bash
# Task picker (Mod+T). Navigates only — it never creates a ticket, so a typo
# fails to match instead of silently building a stray workspace. Creation is
# niri-task-new.sh on Mod+Shift+T.
#
# Rows, in order: live task workspaces (most recently used first), then the
# anchors, then dormant ticket worktrees. The leading glyph says whether the
# workspace exists and holds windows; the second says what Jira thinks of the
# ticket.
#
#   ● has windows   ◌ named but empty   ○ no workspace yet
#   ✓ done          ▸ in progress       · to do
#
# fuzzel runs with --index so the displayed text can carry glyphs and padding
# without anything having to parse it back out.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

nt_require_config

# Render from cache immediately; refresh behind the picker, not in front of it.
if nt_jira_cache_stale; then
    nt_jira_refresh_async
fi

declare -A SUMMARY=() CATEGORY=()
if [[ -f "$JIRA_CACHE" ]]; then
    while IFS=$'\t' read -r key category summary; do
        [[ -z "$key" ]] && continue
        CATEGORY["$key"]="$category"
        SUMMARY["$key"]="$summary"
    done < <(jq -r '.issues[]? | [.key, .category, .summary] | @tsv' "$JIRA_CACHE" 2>/dev/null)
fi

declare -A WS_WINDOWS=()
while IFS=$'\t' read -r name _output count; do
    [[ -z "$name" ]] && continue
    WS_WINDOWS["$name"]="$count"
done < <(nt_named_workspaces 2>/dev/null)

# Ticket worktrees, MRU first, plus how many worktrees share each key.
mapfile -t WORKTREES < <(nt_ticket_worktrees)
declare -A KEY_COUNT=()
for line in "${WORKTREES[@]}"; do
    IFS=$'\t' read -r key _path <<<"$line"
    KEY_COUNT["$key"]=$(( ${KEY_COUNT["$key"]:-0} + 1 ))
done

displays=()
targets=()

add_row() {
    displays+=("$1")
    targets+=("$2")
}

status_glyph() {
    case "${CATEGORY[$1]:-}" in
        done)          printf '✓' ;;
        indeterminate) printf '▸' ;;
        new)           printf '·' ;;
        *)             printf ' ' ;;
    esac
}

occupancy_glyph() {
    local name="$1"
    if [[ -v WS_WINDOWS["$name"] ]]; then
        (( WS_WINDOWS["$name"] > 0 )) && printf '●' || printf '◌'
    else
        printf '○'
    fi
}

trim() {
    local text="$1" width="$2"
    if (( ${#text} > width )); then
        printf '%s…' "${text:0:width-1}"
    else
        printf '%s' "$text"
    fi
}

# Label for a ticket row: the Jira summary when cached, else the directory name.
# Disambiguated by directory only when two worktrees share the key.
ticket_label() {
    local key="$1" path="$2" label
    label="${SUMMARY[$key]:-}"
    [[ -z "$label" ]] && label="${path##*/}"
    if (( ${KEY_COUNT[$key]:-1} > 1 )); then
        label="$label  (${path##*/})"
    fi
    trim "$label" 64
}

declare -A LISTED=()

# 1. Live task workspaces, in worktree MRU order. Rows are tracked by workspace
# name — the worktree directory — rather than by key, so two worktrees sharing a
# key each get their own row instead of the second one being swallowed.
for line in "${WORKTREES[@]}"; do
    IFS=$'\t' read -r key path <<<"$line"
    name="${path##*/}"
    [[ -v LISTED["$name"] ]] && continue
    [[ -v WS_WINDOWS["$name"] ]] || continue
    add_row "$(printf '%s %s %-11s %s' \
        "$(occupancy_glyph "$name")" "$(status_glyph "$key")" "$key" \
        "$(ticket_label "$key" "$path")")" "ws:$name"
    LISTED["$name"]=1
done

# A named task workspace whose worktree has since been removed still deserves a
# row — otherwise its windows become unreachable by name.
for name in "${!WS_WINDOWS[@]}"; do
    nt_is_task_workspace "$name" || continue
    [[ -v LISTED["$name"] ]] && continue
    key="$(nt_key_of_path "$name")"
    add_row "$(printf '%s %s %-11s %s' \
        "$(occupancy_glyph "$name")" "$(status_glyph "$key")" "$key" \
        "$(trim "${SUMMARY[$key]:-no worktree}" 64)")" "ws:$name"
    LISTED["$name"]=1
done

# 2. Anchors.
for anchor in "${ANCHORS[@]}"; do
    add_row "$(printf '%s   %s' "$(occupancy_glyph "$anchor")" "$anchor")" "ws:$anchor"
done

# 3. Dormant ticket worktrees.
for line in "${WORKTREES[@]}"; do
    IFS=$'\t' read -r key path <<<"$line"
    [[ -v LISTED["${path##*/}"] ]] && continue
    add_row "$(printf '○ %s %-11s %s' \
        "$(status_glyph "$key")" "$key" "$(ticket_label "$key" "$path")")" \
        "open:$key:$path"
done

(( ${#displays[@]} )) || nt_die "No task workspaces or ticket worktrees found."

choice="$(printf '%s\n' "${displays[@]}" \
    | fuzzel --dmenu --index --cache=/dev/null --width 100 --prompt 'task> ')"

[[ "$choice" =~ ^[0-9]+$ ]] || exit 0
(( choice < ${#targets[@]} )) || exit 0

target="${targets[$choice]}"
case "$target" in
    ws:*)
        niri msg action focus-workspace "${target#ws:}" >/dev/null 2>&1
        ;;
    open:*)
        rest="${target#open:}"
        nt_open_task "${rest%%:*}" "${rest#*:}"
        ;;
esac
