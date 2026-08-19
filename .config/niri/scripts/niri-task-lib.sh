#!/usr/bin/env bash
# Shared helpers for the Jira-keyed task workspace workflow.
# Design and rationale: docs/adr/0001-niri-task-workspace-workflow.md
#
# Sourced by niri-task.sh, niri-task-new.sh, niri-task-place.sh,
# niri-jira-cache.sh and alacritty_launcher.sh. Not executable on its own.
#
# Work-specific values (Jira host, repository path, project key) deliberately
# live outside this repository, in ~/.work-env; credentials live in ~/.secrets.
# Both are sourced here rather than inherited, because scripts spawned by niri
# get the compositor's environment, not an interactive shell's.

for _nt_env in "$HOME/.work-env" "$HOME/.secrets"; do
    # shellcheck disable=SC1090
    [[ -f "$_nt_env" ]] && source "$_nt_env"
done
unset _nt_env

REPO="${NIRI_TASK_REPO:-}"
DEV_ROOT="${NIRI_TASK_DEV_ROOT:-$HOME/dev}"
PROJECT="${NIRI_TASK_PROJECT:-}"
JIRA_URL="${JIRA_HOST:-}"

BASE_BRANCH="${NIRI_TASK_BASE:-origin/develop}"
BRANCH_PREFIX="${NIRI_TASK_BRANCH_PREFIX:-bugfix/rmc}"

# Task workspaces live on exactly one output; the anchors live on the other.
TASK_OUTPUT="${NIRI_TASK_OUTPUT:-DP-3}"
ANCHOR_OUTPUT="${NIRI_TASK_ANCHOR_OUTPUT:-HDMI-A-1}"
ANCHORS=("comm-tools" "slack" "personal")

BROWSER_CMD="${NIRI_TASK_BROWSER:-google-chrome-stable}"
TERM_CMD="${NIRI_TASK_TERM:-alacritty}"
IDE_CMD="${NIRI_TASK_IDE:-idea}"
IDE_APP_ID="${NIRI_TASK_IDE_APP_ID:-^jetbrains-idea}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/niri-task"
JIRA_CACHE="$CACHE_DIR/jira.json"
JIRA_TTL="${NIRI_TASK_JIRA_TTL:-43200}"   # 12h

# Maps a key to the worktree it was opened from. Lives in the runtime dir
# because its useful lifetime is exactly the workspace's — neither survives a
# reboot. It only matters when two worktrees share one key (…-N and …-N-v2),
# where the recency fallback would otherwise have to guess.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/niri-task"
WS_MAP="$RUNTIME_DIR/map"

SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"

nt_notify() { notify-send "niri-task" "$1" >/dev/null 2>&1 || true; }
nt_die() { nt_notify "$1"; exit 1; }

# Fail loudly and early rather than half-creating things with empty paths.
nt_require_config() {
    local missing=()
    [[ -n "$REPO" ]]      || missing+=("NIRI_TASK_REPO")
    [[ -n "$PROJECT" ]]   || missing+=("NIRI_TASK_PROJECT")
    [[ -n "$JIRA_URL" ]]  || missing+=("JIRA_HOST")
    if (( ${#missing[@]} )); then
        nt_die "Missing in ~/.work-env: ${missing[*]}"
    fi
    [[ -d "$REPO" ]] || nt_die "NIRI_TASK_REPO is not a directory: $REPO"
}

nt_require_credentials() {
    [[ -n "${JIRA_USERNAME:-}" && -n "${JIRA_API_TOKEN:-}" ]] \
        || nt_die "JIRA_USERNAME / JIRA_API_TOKEN not set (expected in ~/.secrets)"
}

# Uppercase project key for a worktree path, or nothing if it is not a ticket
# worktree. Tolerates a trailing -vN, which retried worktrees carry.
nt_key_of_path() {
    local base="${1##*/}" lc="${PROJECT,,}"
    if [[ "$base" =~ -${lc}-([0-9]+)(-v[0-9]+)?$ ]]; then
        printf '%s-%s\n' "$PROJECT" "${BASH_REMATCH[1]}"
    fi
}

# "KEY<TAB>PATH" for every ticket worktree, most recently used first. Recency
# comes from the mtime of the worktree's admin directory under .git/worktrees,
# which git touches on checkout, commit and index updates.
nt_ticket_worktrees() {
    local path key admin ts
    git -C "$REPO" worktree list --porcelain 2>/dev/null \
        | awk '/^worktree /{print $2}' \
        | while read -r path; do
            key="$(nt_key_of_path "$path")"
            [[ -z "$key" ]] && continue
            admin=""
            [[ -f "$path/.git" ]] && admin="$(sed -n 's/^gitdir: //p' "$path/.git")"
            if [[ -n "$admin" && -e "$admin" ]]; then
                ts="$(stat -c %Y "$admin" 2>/dev/null || echo 0)"
            else
                ts="$(stat -c %Y "$path" 2>/dev/null || echo 0)"
            fi
            printf '%s\t%s\t%s\n' "$ts" "$key" "$path"
        done \
        | sort -rn | cut -f2,3
}

# "NAME<TAB>OUTPUT<TAB>WINDOW_COUNT" for every named workspace.
nt_named_workspaces() {
    local ws wins
    ws="$(niri msg -j workspaces)" || return 1
    wins="$(niri msg -j windows)" || return 1
    jq -rn --argjson ws "$ws" --argjson wins "$wins" '
        ($wins | group_by(.workspace_id)
               | map({ key: (.[0].workspace_id | tostring), value: length })
               | from_entries) as $count
        | $ws[]
        | select(.name != null)
        | [ .name, .output, ($count[(.id | tostring)] // 0) ]
        | @tsv'
}

nt_focused_workspace_name() {
    niri msg -j workspaces 2>/dev/null \
        | jq -r 'first(.[] | select(.is_focused) | .name) // empty'
}

nt_window_ids() {
    niri msg -j windows 2>/dev/null | jq -r '.[].id' | sort -n
}

nt_is_ticket_key() { [[ "$1" =~ ^[A-Z][A-Z0-9]*-[0-9]+$ ]]; }

nt_remember() {
    mkdir -p "$RUNTIME_DIR"
    printf '%s\t%s\n' "$1" "$2" >> "$WS_MAP"
}

# Worktree path for a key: the remembered one if this workspace was opened in
# this session, otherwise the most recently used worktree carrying that key.
nt_resolve_worktree() {
    local key="$1" path=""
    if [[ -f "$WS_MAP" ]]; then
        path="$(awk -F'\t' -v k="$key" '$1 == k { p = $2 } END { if (p) print p }' "$WS_MAP")"
        if [[ -n "$path" && -d "$path" ]]; then
            printf '%s\n' "$path"
            return 0
        fi
    fi
    path="$(nt_ticket_worktrees | awk -F'\t' -v k="$key" '$1 == k { print $2; exit }')"
    [[ -n "$path" ]] || return 1
    printf '%s\n' "$path"
}

# Pin the anchors to indices 1..N on their output, in ANCHORS order, so the bar
# reads comm-tools, slack, personal from left to right.
#
# Needed because declaration order in config.kdl is not honoured reliably: on a
# live config reload each newly declared workspace is inserted at the top, so
# three fresh declarations come out reversed, and dock/undock scrambles them too
# (open upstream issue). Addressing by --reference acts on each anchor by name
# without having to focus it first, and the whole thing is idempotent, so it is
# safe to re-run at any time to repair the order.
nt_order_anchors() {
    local index=1 anchor
    for anchor in "${ANCHORS[@]}"; do
        niri msg action move-workspace-to-index "$index" --reference "$anchor" \
            >/dev/null 2>&1
        index=$(( index + 1 ))
    done
}

# Name the always-empty bottom workspace of the task output, and focus it.
# Workspace indices resolve against the focused output, so focus it first.
nt_claim_workspace() {
    local name="$1" count
    niri msg action focus-monitor "$TASK_OUTPUT" >/dev/null 2>&1
    count="$(niri msg -j workspaces \
        | jq --arg o "$TASK_OUTPUT" '[.[] | select(.output == $o)] | length')"
    niri msg action focus-workspace "$count" >/dev/null 2>&1
    niri msg action set-workspace-name "$name" >/dev/null 2>&1
}

# Build a task workspace: three full-width columns, left to right browser,
# terminal, IDE. All three are spawned while the new workspace is focused so
# they land there natively; the placer only corrects the IDE window if focus
# moved away before it mapped.
nt_open_task() {
    local key="$1" dir="$2" before

    nt_remember "$key" "$dir"
    nt_claim_workspace "$key"

    setsid "$BROWSER_CMD" --new-window "$JIRA_URL/browse/$key" >/dev/null 2>&1 &
    setsid "$TERM_CMD" --working-directory "$dir" >/dev/null 2>&1 &

    # The title filter is the worktree directory name, which IntelliJ puts at the
    # front of its project window title. Without it the placer matches IntelliJ's
    # empty-titled splash window first and the real one arrives unplaced.
    before="$(nt_window_ids | paste -sd,)"
    setsid "$IDE_CMD" "$dir" >/dev/null 2>&1 &
    setsid "$SCRIPT_DIR/niri-task-place.sh" "$key" "$IDE_APP_ID" "$before" \
        "${dir##*/}" >/dev/null 2>&1 &
}

# True when the Jira cache is missing or older than the TTL.
nt_jira_cache_stale() {
    local fetched now
    [[ -f "$JIRA_CACHE" ]] || return 0
    fetched="$(jq -r '.fetched // 0' "$JIRA_CACHE" 2>/dev/null || echo 0)"
    now="$(date +%s)"
    (( now - fetched > JIRA_TTL ))
}

nt_jira_refresh_async() {
    setsid "$SCRIPT_DIR/niri-jira-cache.sh" >/dev/null 2>&1 &
}
