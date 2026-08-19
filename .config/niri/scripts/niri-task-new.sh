#!/usr/bin/env bash
# Create a task (Mod+Shift+T): worktree, branch, named workspace, three windows.
#
# Split from the picker on purpose. fuzzel's dmenu mode echoes raw input when
# nothing matches, so a combined key would let "634" fuzzy-match an existing
# ticket and take you somewhere you did not ask for.
#
# The Jira summary is fetched to validate the key before anything is created,
# and displayed while the slug is typed. It is deliberately not slugified
# automatically: real summaries do not reduce to the two or three words that
# make a good directory name.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

nt_require_config
nt_require_credentials

raw="$(fuzzel --dmenu --prompt-only="new ${PROJECT} task> ")" || exit 0
raw="${raw//[[:space:]]/}"
[[ -z "$raw" ]] && exit 0

if [[ "$raw" =~ ^[0-9]+$ ]]; then
    key="$PROJECT-$raw"
elif [[ "$raw" =~ ^[A-Za-z][A-Za-z0-9]*-[0-9]+$ ]]; then
    key="${raw^^}"
else
    nt_die "Not a ticket key: $raw"
fi

# Already open, or already checked out: go there instead of building anything.
if nt_named_workspaces 2>/dev/null | cut -f1 | grep -qxF "$key"; then
    niri msg action focus-workspace "$key" >/dev/null 2>&1
    exit 0
fi
if existing="$(nt_resolve_worktree "$key")"; then
    nt_notify "$key already has a worktree — opening it."
    nt_open_task "$key" "$existing"
    exit 0
fi

response="$(curl -sS -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
    -H 'Accept: application/json' --max-time 20 \
    -w $'\n%{http_code}' \
    "$JIRA_URL/rest/api/3/issue/$key?fields=summary")" \
    || nt_die "Could not reach Jira."

code="$(tail -n1 <<<"$response")"
body="$(sed '$d' <<<"$response")"
[[ "$code" == "200" ]] || nt_die "$key: Jira returned HTTP $code"

summary="$(jq -r '.fields.summary // ""' <<<"$body")"

# The summary is the prompt, so it stays on screen while the slug is typed.
slug_raw="$(fuzzel --dmenu --width 100 \
    --prompt-only="$(printf '%s' "${summary:0:70}") > ")" || exit 0
slug="$(printf '%s' "$slug_raw" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs 'a-z0-9' '-' \
    | sed 's/^-*//; s/-*$//')"
[[ -z "$slug" ]] && exit 0

dir="$DEV_ROOT/$slug-${key,,}"
branch="$BRANCH_PREFIX/$slug-$key"

[[ -e "$dir" ]] && nt_die "$dir already exists."

git -C "$REPO" fetch --quiet origin || nt_die "git fetch failed."

if git -C "$REPO" show-ref --verify --quiet "refs/heads/$branch"; then
    git -C "$REPO" worktree add "$dir" "$branch" >/dev/null 2>&1 \
        || nt_die "worktree add failed for existing branch $branch"
elif git -C "$REPO" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git -C "$REPO" worktree add --track -b "$branch" "$dir" "origin/$branch" >/dev/null 2>&1 \
        || nt_die "worktree add failed tracking origin/$branch"
else
    git -C "$REPO" worktree add -b "$branch" "$dir" "$BASE_BRANCH" >/dev/null 2>&1 \
        || nt_die "worktree add failed from $BASE_BRANCH"
fi

nt_open_task "$key" "$dir"
nt_jira_refresh_async
nt_notify "$key → ${dir##*/}"
