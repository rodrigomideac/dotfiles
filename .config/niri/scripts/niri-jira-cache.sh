#!/usr/bin/env bash
# Refresh the Jira status/summary cache used to annotate the task picker.
#
# One batched request for every ticket worktree, not one per key. Note the
# endpoint: /rest/api/3/search/jql. The long-standing /rest/api/3/search now
# returns 410 Gone.
#
# Run in the background by niri-task.sh when the cache is older than the TTL, so
# the picker renders from cache immediately and never waits on the network.

set -uo pipefail

source "$(dirname -- "$(readlink -f -- "$0")")/niri-task-lib.sh"

nt_require_config
nt_require_credentials

keys="$(nt_ticket_worktrees | cut -f1 | sort -u | paste -sd,)"
[[ -z "$keys" ]] && exit 0

mkdir -p "$CACHE_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp" "$tmp.norm"' EXIT

if ! curl -sSf -u "$JIRA_USERNAME:$JIRA_API_TOKEN" -G \
        -H 'Accept: application/json' \
        --data-urlencode "jql=key in ($keys)" \
        --data-urlencode 'fields=summary,status' \
        --max-time 20 \
        -o "$tmp" "$JIRA_URL/rest/api/3/search/jql"; then
    exit 1
fi

# Keep only what the picker renders, plus a fetch stamp for the TTL check.
jq --argjson now "$(date +%s)" '{
    fetched: $now,
    issues: [ .issues[]? | {
        key,
        summary: ((.fields.summary // "") | sub("^\\s+"; "") | sub("\\s+$"; "")),
        category: (.fields.status.statusCategory.key // ""),
        status: (.fields.status.name // "")
    } ]
}' "$tmp" > "$tmp.norm" || exit 1

mv "$tmp.norm" "$JIRA_CACHE"
