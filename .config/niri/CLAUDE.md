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

- `scripts/niri-desk-lib.sh` - shared helpers for the fixed desk workspaces; see
  the "Workspace model" section at the end of this file

- `scripts/desk-branch.sh` - waybar feed: the branch checked out on the desk
  showing on DP-3

- `scripts/niri-repair-order.sh` - re-pins anchors and desks to their declared
  order on both outputs; bound to `Mod+Shift+T`

- `scripts/niri-window-place.sh` - corrective placement for a slow-starting
  window, by window-id set difference; used by `startup.sh` for Chrome and the
  Outlook/internal PWAs

- `scripts/niri-window-inspect.sh` - discovers the `app-id`/`title` of a window
  so a rule can be written for it; bound to `Mod+F1`/`Mod+F2`, see "Window Rules"

- `scripts/niri-late-window-rules.sh` - floats windows whose title only becomes
  matchable after they are mapped, and places windows under the pointer; both
  are things config.kdl cannot do. Runs as `niri-late-window-rules.service`

- `scripts/niri-place-at-cursor.sh` - moves a floating window to the mouse
  pointer, by id or focused; see "Placing a window at the pointer"

- `scripts/stream-scale.sh` - raises the output scale while this desktop is
  being watched over Moonlight from a laptop; bound to `Mod+Ctrl+Equal` /
  `Mod+Ctrl+Minus` and driven automatically by Sunshine's `global_prep_cmd`.
  See "Remote sessions" at the end of this file

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
output and positions move. See `docs/adr/0003-fixed-colour-desks.md`, which
supersedes 0001's lifecycle and 0002 entirely.

- **HDMI-A-1** holds three permanent anchors: `comm-tools`, `slack`, `personal`
  (`Mod+Q` / `Mod+W` / `Mod+E`).
- **DP-3** holds five permanent **desks**: `blue`, `red`, `green`, `yellow`,
  `crab`. Each is a fixed worktree at `~/dev/<name>` that you point at a branch
  with a plain `git checkout`. Nothing creates, renames or releases them.

All eight are declared in `config.kdl`, so they exist at login and survive a
reboot. There is no picker and no creation keybind; a desk is reached by cycling.

| Bind | Action |
| --- | --- |
| `Mod+Tab` / `Mod+Shift+Tab` | cycle DP-3's *occupied* desks, from either screen |
| `Mod+J` / `Mod+K` | walk occupied named workspaces on the focused output |
| `Mod+Ctrl+J` / `Mod+Ctrl+K` | carry the focused column across *all* named ones |
| `Mod+U` / `Mod+I` | walk the workspace stack on the focused output |
| `Mod+Shift+T` | re-pin workspace order after a dock/undock |
| `Mod+Q` / `Mod+W` / `Mod+E` | the anchors, directly |

**Cycling skips empty desks.** All five exist from login whether or not anything
is open in them, so without the filter most presses land on a bare desk.
`niri-named-workspace.sh` treats a workspace as occupied when its
`active_window_id` is non-null — the workspace JSON carries no window count.

Moving deliberately does *not* filter: carrying a column onto an empty desk is
the only way into one, since there are no direct desk binds. The same asymmetry
means a desk you empty drops out of the cycle until you move something back to
it.

**Order is load-bearing.** With no direct desk binds, the order of the five on
DP-3 *is* the navigation. Declaration order in `config.kdl` is not honoured on a
live reload — each newly declared workspace is inserted at the top, so a fresh
set comes out reversed — and docking or undocking scrambles it again.
`startup.sh` pins it at login via `desk_order`, and `Mod+Shift+T` repairs it in
between. Both are idempotent and safe to re-run.

When acting on a workspace from a script, prefer an explicit reference over
focusing it first:

```bash
niri msg action move-workspace-to-index <n> --reference <name>
niri msg action set-workspace-name --workspace <ref> <new-name>
```

`focus-monitor` lands on whatever workspace that output already had active, not
on the one you had in mind, so a focus-then-act pair can silently act on the
wrong workspace.

# Desk colours

niri cannot colour a workspace. `focus-ring` is global, and window rules match on
`app-id` and `title` only — there is **no `at-workspace`** in niri 26.04, and
`niri validate` rejects it. So each desk tints the focus ring of the two windows
it owns, matched on a title the desk controls:

- IntelliJ puts the project directory name at the front of its frame title.
- `alacritty_launcher.sh` passes `--title <desk>` together with
  `-o window.dynamic_title=false`, because tmux and the shell otherwise rewrite
  the title within a second of the window mapping.

The rules use a word boundary (`^blue\b`) so `blue` does not match a window
called `blueprint`. `crab` is deliberately uncoloured.

The same match also carries `open-on-workspace "<desk>"`, so a desk's windows
land on the desk. `sq ide` is run from a shell, not from the desk it belongs to,
and without this the IDE opens wherever focus happened to be — setting up four
desks in one sitting put two IDEs on the wrong desk and a third on an *unnamed*
workspace, which cycling skips, leaving it unreachable by keyboard. `crab` has a
placement rule despite having no colour.

The same four hues appear in three places and must be changed together:
`config.kdl`'s window rules (bright Gruvbox, for the ring), waybar's `style.css`
(dim Gruvbox, for the bar), and `customColor` in the work repo's `setup-ide`
(bright, for the IntelliJ window header).

# Work-specific values

Not committed. `niri-desk-lib.sh` sources `~/.work-env` — a POSIX-clean file in a
separate private repository — for `CRAB_WORKTREES` and the PWA app-id. It sources
it explicitly rather than inheriting it, because scripts spawned by niri get the
compositor's environment, not an interactive shell's. `~/.secrets` is no longer
read by anything here: nothing in the compositor talks to Jira any more.

Since KDL cannot interpolate environment variables, anything that must stay
uncommitted cannot be matched in a window rule — `startup.sh` places those
windows by window id instead.

## Remote sessions

Sunshine streams this desktop to Moonlight on a 13" laptop. It captures through
`wlr-screencopy`, which hands over the output's *framebuffer* — so the stream is
always the output's mode, 1920x1080, whatever the scale is. That is the whole
reason scale is the knob to reach for: text laid out for a 24" monitor is barely
half its physical size on a 13" panel, and raising the scale fixes that without
the stream losing a single pixel. Lowering the mode would buy the same glyph
size by making the entire picture coarser.

```bash
stream-scale status      # which output is being driven, and its scale
stream-scale up / down   # step through 1 / 1.25 / 1.5 / 1.75 / 2
stream-scale on 1.75     # a specific scale
stream-scale off         # back to 1x for sitting at the desk again
```

The output is `$STREAM_SCALE_OUTPUT`, else Sunshine's `output_name`, else the
only enabled output, else the focused one — set `STREAM_SCALE_OUTPUT` when both
desk monitors are on and the wrong one gets scaled.

`~/.config/sunshine/sunshine.conf` calls `on` and `off` from `global_prep_cmd`,
so a stream scales the desktop up on connect and puts it back on disconnect.
That file is not stowed: Sunshine's web UI rewrites it, and its logs, state and
credentials live in the same directory.

Everything on this desktop is a native Wayland client (`xlsclients` lists only
Zoom's webview), so fractional scales stay sharp. An X11 client arriving through
xwayland-satellite would be upscaled and blurry at anything but 1x or 2x.

