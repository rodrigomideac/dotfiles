# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a configuration repository for **niri**, a scrollable-tiling Wayland compositor. The configuration defines window management behavior, keybindings, visual styling, and custom scripts for the niri window manager.

## Configuration Format

All niri configuration files use **KDL (KDL Document Language)** format. The main configuration file is `config.kdl`.

- KDL specification: <https://kdl.dev>
- Niri configuration documentation: <https://yalter.github.io/niri/Configuration:-Introduction>

## Key Files

- `config.kdl` - Main niri configuration file containing:
  - Input device settings (keyboard, touchpad, mouse)
  - Output/monitor configuration
  - Layout settings (gaps, window sizing, focus behavior)
  - Visual styling (focus rings, borders, shadows)
  - Keybindings for window management and application launching
  - Window rules for specific applications

- `keymap.xkb` - XKB keyboard layout configuration (US International)

- `scripts/niri-task*.sh` - the per-ticket task workspace workflow; see the
  "Workspace model" section at the end of this file

- `scripts/niri-workspace-reaper.sh` - drops a task workspace's name once its
  last window closes, so niri reaps the workspace

- `scripts/niri-window-inspect.sh` - discovers the `app-id`/`title` of a window
  so a rule can be written for it; bound to `Mod+F1`/`Mod+F2`, see "Window Rules"

- `scripts/niri-late-window-rules.sh` - floats windows whose title only becomes
  matchable after they are mapped, and places windows under the pointer; both
  are things config.kdl cannot do. Runs as `niri-late-window-rules.service`

- `scripts/niri-place-at-cursor.sh` - moves a floating window to the mouse
  pointer, by id or focused; see "Placing a window at the pointer"

- `tools/niri-cursor-pos.c` - prints the pointer position, which nothing else
  can; built by `make tools` into `~/.local/bin/niri-cursor-pos`

- `scripts/claude_scratchpad.sh` - Bash script that provides dropdown/scratchpad behavior for Claude AI web app
  - Launches Claude in a Chrome app window with custom class `KagiAssistant`
  - Toggles window visibility by moving it between current workspace and workspace 99
  - Uses state files in `/tmp` to track window visibility
  - Requires `niri`, `google-chrome-stable`, and `jq`

## Common Tasks

### Viewing Current Configuration

```bash
# View current niri configuration
cat ~/.config/niri/config.kdl

# List all outputs/monitors
niri msg outputs

# List all windows with their IDs and properties
niri msg -j windows | jq

# List all workspaces
niri msg -j workspaces | jq
```

### Testing Configuration Changes

```bash
# Check config.kdl for errors without applying it
niri validate

# niri watches the config file and reloads it on save, so no restart is needed;
# the file here is symlinked into ~/.config/niri, so editing it is editing the
# live config. Some settings (e.g. prefer-no-csd) still need the app restarted.
```

### Interacting with niri via IPC

Drive niri programmatically with `niri msg action <action-name> [args]`. Run
`niri msg action --help` for the full list — the common families are:

- `focus-workspace <ref>`, `focus-workspace-{up,down,previous}`
- `move-window-to-workspace <ref>`, `move-window-to-monitor[-{left,right,up,down,previous,next}] [OUTPUT]`
- `focus-monitor[-{left,right,up,down,previous,next}] [OUTPUT]`
- `toggle-overview`

Outputs are named like `HDMI-A-1` / `DP-2` (see `niri msg outputs`).

## Architecture and Key Concepts

### Window Management Model

Niri uses a **scrollable tiling layout** with dynamic workspaces:

- Workspaces are arranged vertically and created/destroyed dynamically
- Windows within a workspace are arranged horizontally in columns
- Columns can contain multiple windows stacked vertically
- Windows can be floating (like picture-in-picture) or tiled

### Keybinding System

Keybindings in `config.kdl` follow this pattern:

```kdl
<Modifier>+<Key> { <action>; }
```

- `Mod` = Super key when on TTY, Alt when in winit window
- Multiple modifiers can be combined with `+`
- Actions can be spawn commands, niri built-in actions, or spawn-sh for shell commands

### Window Rules

Window rules match applications by `app-id` or `title` and apply custom behavior:

```kdl
window-rule {
    match app-id="app-identifier"
    // Properties like open-floating, default-column-width, etc.
}
```

Both fields are regexes and are *unanchored*, so `app-id="firefox$"` catches
`firefox` and `org.mozilla.firefox` alike. Several `match` lines in one rule are
OR'd; `app-id` and `title` inside the same `match` are AND'd. `exclude` carves
cases back out — the Zoom rule floats every helper window except the main one.

Common window rule properties:

- `open-floating` - Launch window in floating mode
- `default-column-width` - Set initial width
- `block-out-from` - Exclude from screen capture
- `geometry-corner-radius` - Set rounded corners
- `default-floating-position` - Where a floating window opens
- `open-on-workspace` - Route the window to a named workspace

#### Finding the app-id and title

Both are only knowable at runtime. `niri-window-inspect.sh` writes a Markdown
report to `~/Documents/niri-windows/<timestamp>-windows.md` — one block per
window with its app-id, title, workspace, size, and a ready-to-paste
`window-rule` whose regexes are already escaped — and notifies with the path.

| Bind | Mode | What it reports |
| --- | --- | --- |
| `Mod+F1` | `focused` | the focused window in full, plus a table of every open window |
| `Mod+F2` | `watch 3` | windows that *appear* in the next 3 seconds |

`Mod+F2` is the one for windows that cannot be focused — splash screens, menus,
toolbars that disappear the moment focus moves. Press it, then do the thing that
makes the window show up. It reads the event stream rather than polling, so a
window that opens and closes inside the interval is still caught and flagged as
having closed. It also lists windows that merely *changed* (a title update) and
the baseline that was already open.

Run it by hand for a longer window: `niri-window-inspect.sh watch 10`. Set
`NIRI_WINDOW_INSPECT_DIR` to write the reports somewhere else.

#### When a title rule cannot work

The `open-*` and `default-*` properties are evaluated **once, when the window is
mapped**. If the app sets its real title only after that, the rule sees the
placeholder and never fires. Firefox does exactly this — every window maps as
`Mozilla Firefox`:

```
{"id":601,"app_id":"firefox_firefox","title":"Mozilla Firefox"}
{"id":601,"app_id":"firefox_firefox","title":"Licenses — Mozilla Firefox"}
```

So no `window-rule` can float Bitwarden's popped-out vault, whose title is the
only thing distinguishing it from any other Firefox window. Watch mode reports
the map-time title as **title at open** and flags the mismatch, which is the
signal that a rule in `config.kdl` is going to be dead on arrival.

Rules that only match late go in `scripts/niri-late-window-rules.sh` instead: it
follows the event stream and acts on the window **by id** once the title lands.
Its `RULES` table is one tab-separated line per window — app-id regex, title
regex, exclude-title regex (`-` for none), width, height (`-` to leave a size
alone) and placement (`-`, or `cursor` to put the window under the pointer), in
POSIX ERE rather than the Rust syntax `config.kdl` uses. Restart it after
editing:

```bash
systemctl --user restart niri-late-window-rules
journalctl --user -u niri-late-window-rules -f
```

Dynamic properties (`opacity`, `block-out-from`, borders, corner radius) are
re-evaluated on every title change, so those *do* work from `config.kdl` with a
late title. Toolkits that title a window before mapping it are fine either way —
the jetbrains `win\d+` rule is one.

#### Placing a window at the pointer

`default-floating-position` takes only the eight screen edges and corners, so no
`window-rule` can put a window where the mouse is. Neither can a script, on its
own: **niri's IPC has no cursor query**, and Wayland deliberately tells no client
where the pointer is outside its own surfaces (`niri msg pick-window` and
`pick-color` both need a click; nothing in `niri msg action` reports a position).

`tools/niri-cursor-pos.c` gets it anyway, by being a Wayland client itself: it
maps an invisible fullscreen layer-shell surface on every output, reads the
`wl_pointer.enter` event the compositor sends the instant that surface appears
under the pointer, prints the coordinates and unmaps. No click, no motion,
nothing drawn, no focus change. Build it with `make tools` from the repo root —
`gcc`, `wayland-scanner` and `libwayland-dev`, with the two protocol XML files
vendored in `tools/protocols/`.

```bash
$ niri-cursor-pos            # output-local logical pixels
1233 604 DP-3
$ niri-cursor-pos --json     # adds compositor-global coordinates
{"x":1233,"y":604,"output":"DP-3","global_x":1233,"global_y":604}
```

`scripts/niri-place-at-cursor.sh` does the arithmetic and the move. The window's
top-left lands 16px below and right of the pointer, flipping to the other side
near the right or bottom edge the way a context menu does, so the pointer stays
*outside* it — `focus-follows-mouse` is on, and a window placed under the pointer
takes focus the moment it appears. `--center` centres it on the pointer instead.

```bash
niri-place-at-cursor.sh                     # the focused window
niri-place-at-cursor.sh --id 557            # by id — how the late rules call it
niri-place-at-cursor.sh --id 557 --size 480,720   # size it is *about* to be
NIRI_PLACE_DEBUG=1 niri-place-at-cursor.sh  # print the arithmetic to stderr
```

Three things it has to work around, all confirmed by measurement here:

- **Two coordinate spaces.** `niri msg -j windows` reports
  `tile_pos_in_workspace_view`, relative to the top-left of the *output*;
  `move-floating-window -x/-y` takes coordinates relative to the top-left of the
  *working area* — the output minus what waybar and friends reserve (65px at the
  top here). The offset is not queryable, so it is measured once per output
  (park the window at `-x 0 -y 0`, read where it landed) and cached in
  `$XDG_RUNTIME_DIR/niri-workarea/`. `--recalibrate` forces a fresh measurement.
  `-x`/`-y` also take relative values (`+50`, `-30`).
- **Pointer focus is deferred during animations.** The enter event usually
  arrives in a millisecond or two, but ~335ms while niri animates a window open
  — exactly when a rule places a window that has just appeared. Hence the 2s
  default timeout in `niri-cursor-pos`; it costs nothing, since the wait ends on
  the event rather than on the clock.
- **A resize is only reported once the client acks it.** A caller that just ran
  `set-window-width`/`set-window-height` must pass `--size`, or the edge clamping
  works off the stale size and slams the window into a corner.

niri itself only keeps a floating window *partly* on screen — `-y -1000` on a
200px-tall window leaves 115px visible — so the script does its own clamping.

The Zoom rule in the `RULES` table is deliberately a **catch-all** — `.*` for the
title, with the windows that have a place of their own (the main window, the
screen-share bar, the chat panel) carved back out by the exclude column.
Enumerating popup titles was a losing game: each meeting turned up another one
("meeting bottombar popup" after "Zoom AI is on"), and a title the table does not
know about lands stacked in the top-left corner.

A catch-all is what makes the late-title guard necessary, and why placement
re-reads the title after 150ms and re-checks the exclude before moving anything.
A rule matches on whatever title the window *mapped* with, and the main Zoom
window — usually tiled, so placing it would also drag it out of the layout and
float it — must never be moved on the strength of a placeholder title.

### Custom Scripts Integration

The Claude scratchpad script (bound to `Mod+X`) demonstrates:

- Using `niri msg -j` for querying window/workspace state via JSON
- Using `niri msg action` for programmatic window manipulation
- State management with temporary files
- Focus handling for floating windows using `switch-focus-between-floating-and-tiling`

## Configuration Locations

This config lives in `~/.dotfiles/.config/niri/` and is symlinked to
`~/.config/niri/` via GNU Stow (`make stow` from the repo root). Editing a file
here edits the live config.

When making changes:

- Edit files in the repo (`~/.dotfiles/.config/niri/`)
- Reload niri configuration to apply changes
- Some changes require restarting affected applications (noted in config comments)

## Important Notes

- **Screenshot path**: Currently set to `~/Pictures/Screenshots/`
- **XKB keymap**: US International layout loaded from `keymap.xkb`
- **Focus behavior**: `focus-follows-mouse` is enabled with `max-scroll-amount="0%"`
- **Visual styling**: Shadows enabled, focus ring active, borders disabled
- **Touchpad**: Natural scrolling and tap-to-click enabled

# Monitor Configuration

Principal monitor: HDMI-A-1 (positioned to the **left**, x = -1920)
Side monitor: DP-3 (positioned to the **right**, x = 0)

Note the geometry: `focus-monitor-right` reaches the *side* monitor and
`focus-monitor-left` the principal one. An older `DP-2` no longer exists.

# Workspace model

Workspaces are addressed **by name only** — there are deliberately no numeric
workspace binds, because a niri workspace index is a position on the focused
output and positions move. See `docs/adr/0001-niri-task-workspace-workflow.md`
for the full rationale, and `docs/adr/0002-workspace-named-after-worktree.md`
for the naming.

- **HDMI-A-1** holds three permanent anchors declared in `config.kdl`:
  `comm-tools`, `slack`, `personal` (`Mod+Q` / `Mod+W` / `Mod+E`).
- **DP-3** holds only task workspaces, created on demand, one per ticket
  worktree and **named after that worktree's directory** —
  `<slug>-<key-lowercased>`, e.g. `fix-parsing-error-cron-schedule-proj-1234`.
  The ticket key is recovered from the name with `nt_key_of_path` and the
  worktree with `nt_worktree_of_workspace`; both are exact, since the workspace
  name is the directory name.

| Bind | Action |
| --- | --- |
| `Mod+T` | picker: go to a task workspace or a dormant ticket worktree |
| `Mod+Shift+T` | create a task from a ticket key (worktree, branch, windows) |
| `Mod+Ctrl+T` | `unset-workspace-name` — release the current workspace |
| `Mod+Tab` / `Mod+Shift+Tab` | cycle DP-3's task workspaces, from either screen |
| `Mod+U` / `Mod+I` | walk the task stack on the focused output |
| `Mod+J` / `Mod+K` | walk *named* workspaces on the focused output |

Releasing a workspace drops its name; niri reaps it as soon as it is empty, so
an empty named workspace disappears the moment it is released. `Mod+Ctrl+T` does
the focused one, and any of them can be released without going there first —
both actions take an optional workspace reference:

```bash
niri msg action unset-workspace-name <name>              # positional
niri msg action set-workspace-name --workspace <ref> <new-name>
```

Prefer those references to focusing a workspace and acting on the focused one.
`focus-monitor` lands on whatever workspace that output already had active, not
on the one you had in mind, so a focus-then-rename pair can silently rename the
wrong workspace.

Closing a task's last window releases it too: `niri-workspace-reaper.sh` watches
the event stream and unsets the name of any empty *task* workspace, which is how
a finished ticket leaves `Mod+Tab` and the overview without a keypress. Only
names that parse as a worktree directory are candidates (`nt_is_task_workspace`),
so the three anchors are never touched. A workspace seen holding a window and
then emptied settles for `NIRI_TASK_REAP_SETTLE` seconds (3) before it goes; one
that has never held a window waits `NIRI_TASK_REAP_GRACE` (60), because
`nt_open_task` names a workspace before spawning anything into it.

It runs as a user unit, `niri-workspace-reaper.service`, rather than as another
`startup.sh` spawn: it is the only long-lived process in this workflow, and the
only one that has to come back if it dies. `BindsTo=niri.service` ties it to the
compositor's lifetime and the checked-in symlink under
`.config/systemd/user/niri.service.wants/` means it needs no `systemctl enable`
on a new machine. niri exports `NIRI_SOCKET` and `WAYLAND_DISPLAY` into the
systemd user environment, so `niri msg` works from the unit; the work-specific
values it needs come from `~/.work-env`, which `niri-task-lib.sh` sources
explicitly anyway.

```bash
systemctl --user restart niri-workspace-reaper   # after editing the script
journalctl --user -u niri-workspace-reaper -f
```

The scripts behind these live in `scripts/` here: `niri-task.sh`,
`niri-task-new.sh`, `niri-task-place.sh`, `niri-jira-cache.sh`, with shared
helpers in `niri-task-lib.sh`.

A task workspace's terminal runs `dev` (the tmux-session function from the
interactive shell), and on a **newly created** worktree runs `$POST_HOOK_PATH`
before it, chained with `&&`. The hook is the repository-specific setup run —
install, build, open the IDE — so it is named in `~/.work-env` and lives
outside this repo. When it is set, the fresh path skips the direct IDE spawn
(the hook opens it) and raises `NIRI_TASK_PLACE_TIMEOUT` so the placer outlasts
the build. Unset it and task terminals just run `dev`.

Work-specific values are **not** committed. `niri-task-lib.sh` sources
`~/.work-env` (repository path, project key, tracker host, `POST_HOOK_PATH` — a
POSIX-clean file in a separate private repository) and `~/.secrets`
(credentials). It sources them
explicitly rather than inheriting them, because scripts spawned by niri get the
compositor's environment, not an interactive shell's. Since KDL cannot
interpolate environment variables, anything that must stay uncommitted cannot be
matched in a window rule — `startup.sh` places those windows by window id
instead.
