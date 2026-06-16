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
# Validate configuration (niri will report syntax errors on reload)
# No dedicated validate command exists - test by reloading

# Reload configuration without restarting niri
# Changes take effect immediately for most settings
# Note: Some settings like prefer-no-csd require app restart
niri msg action quit
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

Common window rule properties:

- `open-floating` - Launch window in floating mode
- `default-column-width` - Set initial width
- `block-out-from` - Exclude from screen capture
- `geometry-corner-radius` - Set rounded corners

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

Principal monitor: HDMI-A-1
Side monitor: DP-2
