# 2. Task workspaces are named after their worktree directory

- **Status:** accepted
- **Date:** 2026-08-21
- **Scope:** `.config/niri/`, `.config/waybar/`
- **Supersedes:** the "One identifier" naming rule of
  [ADR 0001](0001-niri-task-workspace-workflow.md)

## Context

ADR 0001 named each task workspace after the bare ticket key — workspace
`PROJ-1234` for worktree `<slug>-proj-1234`. The slug was deliberately left out
because waybar's `niri/workspaces` module prints every name in full, with no
`rewrite` and no tooltip, so long names would push the rest of the bar off the
screen.

Three costs came with that:

- **The name says which ticket, never what the work is.** `PROJ-1234` on the
  bar is a lookup, not a label; the ticket number is the one part of the
  context that is not self-explanatory.
- **The key is not unique.** A retried worktree (`…-1234-v2`) carries the same
  key as the original, so its workspace could not be distinguished from the
  first, and resolving a workspace back to its worktree needed a
  most-recently-used guess plus a runtime map to pin the choice.
- **A whole waybar module existed to undo the omission.** `custom/task-slug`
  did nothing but walk key → worktree → slug in order to display the slug that
  the workspace name could have carried directly.

The constraint that motivated the short name has since lapsed: `niri/workspaces`
is not on the bar at all. Only the focused workspace is displayed, and one name
at a time costs nothing in width.

## Decision

A task workspace is named after its worktree's directory:
`<slug>-<key-lowercased>`, e.g. `fix-parsing-error-cron-schedule-proj-1234`.
Worktree, branch and workspace all still carry the key; the workspace now
carries the slug as well.

The name is a directory name, so every direction is a string operation on it:

| Direction | Mechanism |
| --- | --- |
| create | `nt_open_task` names the workspace `${dir##*/}` |
| workspace → worktree | `nt_worktree_of_workspace` — exact match on the directory name, no recency guess |
| workspace → key | `nt_key_of_path`, the same parser used on paths, because the name *is* a path's last component |
| key → workspace | `Mod+Shift+T` scans named workspaces and compares parsed keys |

Consequently:

- The picker tracks rows by workspace name rather than by key, so two worktrees
  of one ticket list and open separately instead of the second being swallowed.
- `custom/task-slug` prints the focused workspace name verbatim. It resolves
  nothing, needs no work configuration, and keeps its id only because that id
  is a selector in `style.css`.
- `nt_is_ticket_key` is gone. The predicate is now `nt_is_task_workspace`:
  "does this name parse as a worktree directory name".

## Consequences

Positive:

- The bar states the work, not a number to look up.
- One workspace per worktree, guaranteed distinct, including `…-v2` retries.
- `Mod+Return` resolves the worktree exactly instead of preferring the most
  recently used candidate.
- The waybar module lost its entire resolution path.

Accepted costs and known limits:

- **Names are long.** Putting `niri/workspaces` back on the bar would now
  require `format`/rewrite or `current-only`, which ADR 0001 rejected for
  separate reasons. The anchors are unaffected — they keep their short names.
- **A hand-named workspace that happens to parse** (`foo-proj-1`) is treated as
  a task workspace with no worktree. The picker already renders exactly that
  case as `no worktree`, and `Mod+Return` falls back to `/tmp/whereami`.
- **Workspaces named under the old scheme are not migrated automatically.**
  `set-workspace-name --workspace <key> <dir-name>` renames a live one; the
  question disappears at the next reboot, since task workspaces are not
  restored.
- The runtime map under `$XDG_RUNTIME_DIR` is still written, but now matters
  only for key → worktree at creation time — the workspace → worktree direction
  no longer guesses.

## Alternatives rejected

- **Keep the key as the name and keep showing the slug on the bar.** The status
  quo. It preserves both the resolution machinery and the `…-v2` ambiguity in
  order to save width that nothing is currently competing for.
- **`<key>-<slug>` (key first).** Sorts and truncates more nicely, but it is no
  longer the directory name, so it stops being usable as the lookup key for the
  terminal, the placer and the picker — which is the whole point of the change.
- **The full ticket summary in the name.** Rejected in ADR 0001 on width, and
  again here on substance: the slug is already the short human name for the
  work, typed by hand at creation precisely because summaries do not reduce to
  it automatically.
