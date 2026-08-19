# 1. Ticket-keyed task workspaces in niri

- **Status:** accepted
- **Date:** 2026-08-17
- **Scope:** `.config/niri/`, `.config/waybar/`, `scripts/`

## Context

Day-to-day work happens in several git worktrees of one repository at a time,
each worktree corresponding to one issue tracker ticket. Each ticket needs a
browser, a terminal and an IDE. Before this change, workspaces were addressed
positionally: `Mod+1..9` ran `focus-monitor-right && focus-workspace N`, and
`Mod+Q/W/E` did the same for the left monitor.

Positional addressing does not survive niri's dynamic workspace model. Workspace
indices are not properties of the workspace — `focus-workspace 3` means "whatever
is third on the focused output right now". Closing a workspace, reordering, or
unplugging a monitor silently repoints every numeric bind. In practice this meant
windows for two different tickets accumulating on one workspace, and no way to
tell from the screen which ticket a window belonged to.

Several pre-existing defects made this worse and are fixed here:

- `startup.sh` targeted `DP-2`, an output that no longer exists (the side monitor
  is now `DP-3`), so half of the login setup silently did nothing.
- The numeric binds addressed `focus-monitor-right` — which is the *side*
  monitor — while the letter binds addressed the principal one. The labels and
  the behaviour were inverted.
- `waybar` declared a `sway/workspaces` module that was never listed in any
  `modules-*` array, and which cannot work under niri regardless (no sway IPC).
  There was no workspace indicator at all.
- `Mod+Return` opens a terminal in `/tmp/whereami`, a single global file
  overwritten by every shell prompt. With more than one worktree open it opens in
  whichever worktree last drew a prompt, not the one on screen.

## Decision

### One identifier

The ticket key is the only identifier. Workspace `PROJ-1234` ↔ worktree
`$NIRI_TASK_DEV_ROOT/<slug>-proj-1234` ↔ branch `<prefix>/<slug>-PROJ-1234`. The
key is a substring of the directory, the branch and the IDE window title, so
resolution works in every direction with one case-insensitive match.

The ticket summary is deliberately *not* part of the workspace name. waybar's
`niri/workspaces` module has no `rewrite` and no `tooltip` and prints `{value}`
in full, so a name carrying a full summary would render at full width and push
other modules off the bar. Context comes from the `niri/window` module instead,
which shows the focused window's title — and the IDE's title already begins with
the worktree directory name.

### Two outputs, two roles

| Output | Role | Workspaces |
| --- | --- | --- |
| `HDMI-A-1` (left) | reference — things you check | `comm-tools`, `slack`, `personal`; declared in config, permanent |
| `DP-3` (right) | work — things you build in | one named workspace per ticket key, created on demand |

Because `DP-3` holds *only* task workspaces, the existing `Mod+U`/`Mod+I`
(`focus-workspace-down`/`up`) binds already walk the task list. No cycling
mechanism had to be added.

Addressing is by name only. `Mod+1..9` and `Mod+Ctrl+1..9` are deleted.

### A task workspace

Three full-width columns, left to right: browser, terminal, IDE. This requires no
layout configuration — `default-column-width { proportion 1.0 }` was already set,
so every window is already full width and navigation is horizontal scrolling
rather than splitting.

### Creation and navigation are separate keys

`Mod+T` navigates only; its list contains exclusively things that already exist.
`Mod+Shift+T` creates. They were split because fuzzel's dmenu mode prints the raw
input when nothing matches, so a single key would mean typing a partial key to
create a new ticket could fuzzy-match an existing one and silently take you to the
wrong place. Navigation happens dozens of times a day and creation twice a week;
they should not share a keystroke.

### Window placement by snapshot-diff, not by title

All three windows are spawned while the new workspace is focused, so they land
there natively. A background poll then *corrects* placement only if focus moved
away before a slow application (the IDE) mapped its window: the set of window ids
is recorded before spawning, the new id is identified by difference, and
`move-window-to-workspace --window-id … --focus false` relocates it.

Title matching was rejected: two worktrees can exist for one ticket (`…-1234` and
a retried `…-1234-v2`), and both titles contain the same key, so a
`contains`-based match picks whichever it finds first.

Chrome deliberately has **no** `open-on-workspace` window rule. Its `app-id` is
`google-chrome` for both the anchor window and every per-task browser, so any
app-id rule would hijack all of them. `--class` is not an option either: it only
affects windows created by the process it was passed to, and a second
`google-chrome-stable --new-window` invocation merely messages the already-running
instance.

### Issue tracker integration

`Mod+Shift+T` resolves the ticket summary through the tracker's REST API. The
summary is shown while the slug is typed, and a 404 aborts before any worktree is
created.

A cache at `${XDG_CACHE_HOME}/niri-task/jira.json` (12 hour TTL, refreshed in the
background so the picker never blocks on the network) lets the picker annotate
each row with ticket status. This is what makes a pile of finished worktrees
legible without deleting anything.

Note the endpoint: batched lookups use `GET /rest/api/3/search/jql`. The
long-standing `GET /rest/api/3/search` now returns **410 Gone**.

### Configuration and secrets stay out of this repository

Nothing employer-specific is committed here. The scripts read:

- `~/.work-env` — non-secret work configuration (`JIRA_HOST`, `NIRI_TASK_REPO`,
  `NIRI_TASK_DEV_ROOT`, `NIRI_TASK_PROJECT`, `NIRI_TASK_COMM_PWA_ID`), kept in a
  separate private repository and symlinked into `$HOME`.
- `~/.secrets` — credentials (`JIRA_USERNAME`, `JIRA_API_TOKEN`).

Both are sourced explicitly by `niri-task-lib.sh` rather than inherited, because
scripts spawned by niri get the compositor's environment, not an interactive
shell's. `~/.work-env` exists separately from the pre-existing `.work-aliasrc`
because that file is zsh-only (extended globs, `setopt`) and fails `bash -n`;
`~/.work-env` is POSIX-clean so both shells can source it, and `.work-aliasrc`
sources it in turn so interactive shells are unaffected.

One consequence: KDL cannot interpolate environment variables, so a window rule
cannot reference a value held in `~/.work-env`. The internal PWA that belongs on
`comm-tools` therefore gets no window rule; `startup.sh` launches it by id from
the environment and places it with the same snapshot-diff helper.

### Lifecycle

Worktrees are created on demand and **never removed** automatically. Removal is
gardening, and a `git worktree remove` bound next to a "switch task" key is a bad
neighbour; the accumulated worktrees are evidence that automated cleanup was not
trusted. Instead the picker marks which tickets the tracker reports as done.

Workspaces are released, not closed: `Mod+Ctrl+T` runs the native
`unset-workspace-name`, after which niri reaps the workspace once it empties. A
"close everything" variant was rejected as one keystroke away from discarding an
editor with unsaved buffers.

Named workspaces are **not** restored after a reboot. Restoring them would either
cold-start several IDEs at login, or leave empty named workspaces on the bar that
look like live work. The picker is MRU-ordered, so resuming yesterday's ticket is
`Mod+T` followed by Enter.

## Bindings

| Bind | Action |
| --- | --- |
| `Mod+T` | task picker — navigate to an existing workspace or dormant worktree |
| `Mod+Shift+T` | create a new task from a ticket key |
| `Mod+Ctrl+T` | `unset-workspace-name` — release this workspace |
| `Mod+Tab` | `focus-workspace-previous` |
| `Mod+Q` / `Mod+W` / `Mod+E` | `comm-tools` / `slack` / `personal` |
| `Mod+U` / `Mod+I` | walk the task stack on `DP-3` (unchanged) |
| `Mod+Return` | terminal in the focused workspace's worktree |
| `Mod+1..9`, `Mod+Ctrl+1..9` | removed |

## Files

| Path | Role |
| --- | --- |
| `.config/niri/scripts/niri-task-lib.sh` | shared helpers; sourced, not executed |
| `.config/niri/scripts/niri-task.sh` | the picker (`Mod+T`), navigate only |
| `.config/niri/scripts/niri-task-new.sh` | create a task (`Mod+Shift+T`) |
| `.config/niri/scripts/niri-task-place.sh` | corrective window placement by id |
| `.config/niri/scripts/niri-jira-cache.sh` | batched status/summary cache refresh |
| `.config/niri/scripts/alacritty_launcher.sh` | workspace-aware terminal |
| `.config/niri/scripts/startup.sh` | anchors at login; no task restore |

`scripts/alacritty_launcher` was a near-identical duplicate of the niri copy and
is now a symlink to it.

## Consequences

Positive:

- A workspace name fully determines both what is in it and where it is.
- Adding an Nth ticket changes no bindings and renumbers nothing.
- The bar states what each screen is for: anchors on the left, tickets on the
  right (`all-outputs: false`).
- `Mod+Return` becomes correct rather than coincidentally correct.

Accepted costs and known limits:

- **Named workspace ordering is not dependable on its own.** Declaration order in
  `config.kdl` is not honoured on a live config reload — each newly declared
  workspace is inserted at the top, so three fresh declarations come out
  reversed — and dock/undock scrambles the order too (open upstream issue).
  Mitigated by `nt_order_anchors`, which pins each anchor to its index by name
  (`move-workspace-to-index --reference`) and runs from `startup.sh` at every
  login. It is idempotent and does not require focusing the workspaces, so it can
  be re-run at any time to repair the order. Residual: a mid-session dock/undock
  still scrambles them until it is run again. Separately, if `HDMI-A-1` is absent
  entirely, all three anchors fall onto `DP-3` alongside the tasks.
- **`niri/window` is the only context line.** With the browser focused it shows
  the page title, not the ticket. If that becomes annoying, the fix is a
  `custom/` module mapping the focused workspace name to the cached summary.
- **Two worktrees can map to one key** (`…-1234` and `…-1234-v2`). Resolution
  prefers the most recently used, and a runtime map under `$XDG_RUNTIME_DIR` pins
  the choice for as long as the workspace lives — which is exactly as long as the
  workspace itself, since neither survives a reboot.
- **The snapshot-diff poll** mis-attributes if a second IDE window is opened
  manually during its two-second window. Rare, and visible when it happens.
- Non-ticket worktrees (long-lived integration checkouts, the main checkout) are
  deliberately absent from the picker; they are reached as before.

## Alternatives rejected

- **Hybrid positional + named addressing.** Keeping `Mod+1..9` as a fallback on
  the same output as the named workspaces reintroduces two mental models for one
  screen — the problem being solved.
- **Dynamic numeric slots** (`Mod+N` = "the Nth active task", ordered by a
  script-maintained file). Restores the original failure — a number meaning
  different things depending on hidden state — with the state now in a file that
  has no on-screen representation when it disagrees with reality.
- **`current-only: true` on the bar** to allow long self-describing names.
  Deletes the one thing named workspaces buy: seeing the other tasks without
  pressing anything.
- **A task workspace spanning both outputs** (IDE left, browser right). niri has
  no paired-workspace concept, so every `focus-workspace` would leave half the
  task behind.
- **Firefox for tasks, Chrome for anchors**, which would have made window rules
  sufficient. Rejected because Chrome carries the work session and its PWAs;
  Firefox is the personal browser and lives on `personal`.
- **Reading the ticket from the browser's window title** as a zero-credential
  alternative to the API. It silently does the wrong thing whenever the focused
  tab is not an issue page.
- **Auto-slugifying the ticket summary** into the worktree name. Measured against
  real data, summaries do not reduce to the two or three words that make a good
  directory name — the existing slugs drop and reorder words — so the summary is
  displayed and the slug is typed.
