# 3. Five fixed desks, named after colours

- **Status:** accepted
- **Date:** 2026-09-16
- **Scope:** `.config/niri/`, `.config/waybar/`, `.config/systemd/user/`, and
  the work repository's `setup-ide` / `.work-env`
- **Supersedes:** the workspace lifecycle of
  [ADR 0001](0001-niri-task-workspace-workflow.md) — on-demand creation,
  release, reaping and non-restoration — and the whole of
  [ADR 0002](0002-workspace-named-after-worktree.md)

## Context

ADR 0001 gave every ticket its own worktree, branch, named workspace and three
windows, created on demand by `Mod+Shift+T`. ADR 0002 then named the workspace
after the worktree directory so that the name said what the work was.

Both are correct about naming and about addressing by name rather than by index.
What they got wrong is the lifetime. One workspace per ticket means the number
of workspaces is the number of tickets, and that number only goes up:

- **`~/dev` reached 25 worktrees**, plus `crab`, `crab-1`, `develop`,
  `develop1` and `develop2`. One stale directory is no longer a registered
  worktree at all and one worktree is sitting in detached HEAD.
- **Each one carries a full IDE.** `~/sq/ide` holds 26 workspaces *and* 26
  complete IntelliJ installations, at gigabytes apiece.
- **The eight-minute first open is paid per ticket.** The index is per
  workspace and is not carried between them, so every new worktree buys another
  cold Gradle sync.
- **Everything was keyed by a name that changes.** Worktree directory, branch,
  workspace, tmux session and IDE workspace all derive from a slug typed at
  creation. Nothing could be permanent, because the key itself was per-ticket.

The work does not actually need one workspace per ticket. It needs a handful of
places to *be* — a desk you sit at, with an IDE already indexed and a database
already pointed at it — and the ability to move a branch onto one.

## Decision

There are exactly five desks, and nothing creates a sixth:

| Desk | Directory | Niri workspace | Colour |
| --- | --- | --- | --- |
| blue | `~/dev/blue` | `blue` | `#458588` bar / `#83a598` ring |
| red | `~/dev/red` | `red` | `#cc241d` / `#fb4934` |
| green | `~/dev/green` | `green` | `#98971a` / `#b8bb26` |
| yellow | `~/dev/yellow` | `yellow` | `#d79921` / `#fabd2f` |
| crab | `~/dev/crab` | `crab` | neutral |

A colour is a **desk, not a project**. It rotates: you point a desk at a branch
with a plain `git checkout` inside it, and there is no command that does this
for you. `crab` is the main clone, a fifth workbench with no colour.

Consequently:

- **The five workspaces are declared in `config.kdl`**, like the anchors. They
  exist at login, persist while empty, survive a reboot, and are never released.
- **`niri-workspace-reaper.service` is deleted.** It existed to unname task
  workspaces once they emptied; with a fixed set there is nothing to collect and
  its only possible effect is to break a desk.
- **`Mod+T`, `Mod+Shift+T` (create) and `Mod+Ctrl+T` are deleted** along with
  the scripts behind them. Desks are reached by cycling only — `Mod+Tab` from
  either screen, `Mod+J`/`Mod+K` on the desk output.
- **Cycling skips empty desks, moving does not.** Permanent workspaces mean
  permanently *empty* workspaces: with four colours declared and one or two in
  use, most presses would land on a bare desk. Focus therefore walks only
  workspaces with a window in them. `move` keeps walking all of them, because
  carrying a column onto an empty desk is the only way into one.
- **`Mod+Shift+T` is reused to repair workspace order.** Declaration order is
  not honoured on a live reload and dock/undock scrambles it; with no direct
  binds, order *is* the navigation.
- **`setup-ide` is a script**, takes a desk name from the fixed list, creates the
  worktree on a `dummy-<colour>` parking branch when it is missing, and writes
  the desk's colour into `.idea/workspace.xml`.
- **`feature` / `feature-merge` are deleted.** They were the other worktree
  creator. Branch and merge with git from `~/dev/crab`.

### Why the colour cannot come from niri

niri has no per-workspace colour. `focus-ring` is global, and window rules match
on `app-id` and `title` only — there is no `at-workspace` in niri 26.04, which
`niri validate` confirms by rejecting it outright. So each desk tints the focus
ring of the two windows it owns, matched on a title the desk controls: IntelliJ
puts the project directory name at the front of its frame title, and
`alacritty_launcher.sh` passes `--title <desk>` with `dynamic_title` off.

ADR 0001 rejected title matching for window *placement*, and was right to. The
failure mode there was a window landing on the wrong workspace; here it is a ring
in the wrong colour.

The rules do place windows after all, though — `open-on-workspace` on the same
match. 0001's objection was to matching a *ticket slug* typed at creation time
against a title the application controlled. A desk name is neither: it is one of
five fixed strings that the desk itself puts in the title, via the project
directory name or `--title`. The risk that remains is a stray match sending a
window to a desk, which a word boundary and an `app-id` filter make remote.

It is needed because `sq ide` is run from a shell rather than from the desk. The
first four-desk setup left two IDEs on the wrong desk and one on an unnamed
workspace — which cycling skips, so it could not be reached by keyboard at all.

### Why cycling-only does not reintroduce positional addressing

ADR 0001 deleted `Mod+1..9` because an index is a position on the focused output
and positions move. That objection is about *indices*, not about direct binds —
`Mod+1 { focus-workspace "blue"; }` names a literal workspace and the digit is
only a label. Direct binds were nevertheless not taken: mnemonic letters are
unavailable (`Mod+B` is speech-to-text, `Mod+R` is column width; only `G` and `Y`
of `b/r/g/y` are free), and five desks are at most two presses apart by cycling.

## Consequences

Positive:

- The eight-minute index is paid **once per desk** instead of once per ticket,
  which is the whole point.
- The IDE project colour is keyed to the directory, so it is written once and
  survives every branch the desk will ever hold.
- `niri/workspaces` goes back on the bar. ADR 0002's stated reason for taking it
  off was that names had become 40 characters long; `blue` is four.
- Two worktree creators, one picker, one Jira cache, one reaper and a runtime
  key→worktree map all disappear.
- Nothing depends on Jira any more. The compositor no longer reads `~/.secrets`.

Accepted costs and known limits:

- **`git checkout` fails while a branch is checked out in another worktree.**
  With 25 legacy worktrees still registered this will happen. Pruning them is
  deliberately out of scope here and has no script yet.
- **The 26 legacy IDE workspaces and IntelliJ copies under `~/sq/ide` stay.**
  Same deferral, same gigabytes.
- **The terminal's title no longer tracks the running program.** Freezing it is
  what makes the per-desk tint possible; tmux's status line already says what is
  running.
- **`customColor`'s serialized form is assumed, not verified.** One sample on
  disk carried an empty string. A rejected value renders as no colour, and
  falling back to `associatedIndex` is a one-line change.
- **The branch readout is polled, not event-driven.** `git checkout` fires no
  compositor event, so the bar can lag a checkout by up to five seconds.
- **A desk holds whatever you last left in it.** Nothing warns that `blue` is
  still on last week's branch; the bar showing `dummy-blue` is the only "this
  desk is free" signal.
- **An emptied desk drops out of the cycle** until something is moved back onto
  it with `Mod+Ctrl+J`/`Mod+Ctrl+K`. Closing the last window on a desk therefore
  makes it unreachable by `Mod+Tab`, which is the price of not stopping on four
  empty desks all day. The bar still shows it.

## Alternatives rejected

- **Pinned roles per colour** (green = long-lived feature, red = hotfix, …).
  Semantically richer, but four fixed purposes strand work within a week at the
  rate `~/dev` was growing. A desk is a place to sit, not a category.
- **A registry file generating the niri and waybar fragments.** One source of
  truth for five names and eight hex values, at the cost of a build step that
  writes into a second git repository and leaves uncommitted diffs to notice.
  The names will never change; honest duplication with a comment pointing at the
  other two files is cheaper.
- **A command to rebind a desk to a branch.** `git checkout` already is that
  command. Wrapping it would add a thing to learn and a thing to keep correct.
- **Folding `prepare-sq-crab.sh` into `setup-ide`.** It would make `setup-ide`
  an eight-minute command, which defeats the split between "make this desk
  buildable" and "make this desk's IDE mine".
- **Keeping the reaper, taught to skip colours.** Added code whose only purpose
  is to stop existing code from breaking the new model.
- **Writing the colour to `recentProjects.xml` as well.** It is a cache the IDE
  rewrites constantly; `.idea/workspace.xml` is the authority.
