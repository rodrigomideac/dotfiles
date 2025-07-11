# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim configuration based on Kickstart.nvim with extensive customizations. The configuration follows a modular approach with custom plugins, keymaps, and user commands organized in the `lua/custom/` directory.

## Architecture

The configuration is structured as follows:

- **`init.lua`**: Main entry point based on Kickstart.nvim template, contains core settings and plugin setup
- **`lua/custom/`**: All custom modifications and extensions
  - `keymaps.lua`: Custom key mappings including unconventional movement keys (j/k/l/; for left/down/up/right)
  - `user_commands.lua`: Custom user commands for diagnostics and file operations
  - `plugins/`: Custom plugin configurations and additional plugins
  - `mise.lua`: Mise (development environment) integration
- **`lazy-lock.json`**: Locked plugin versions managed by lazy.nvim

## Key Architectural Decisions

### Custom Movement Keys
This configuration uses an unconventional movement scheme:
- `j` = left
- `k` = down  
- `l` = up
- `;` = right

This affects all navigation in normal and visual modes, and window movement uses `Ctrl` + these keys.

### Plugin Management
- Uses lazy.nvim for plugin management
- Plugins are split between kickstart defaults and custom additions in `lua/custom/plugins/`
- Language servers are managed through Mason with automatic installation

### LSP Configuration
- Multiple language servers configured: Go, Python, Rust, TypeScript, Lua, Java, C/C++
- Special handling for Scala (nvim-metals) and Kotlin
- Automatic formatting on save with conform.nvim
- Diagnostics can be toggled via custom commands

## Common Development Commands

### Plugin Management
```
:Lazy                    # Open lazy.nvim plugin manager
:Lazy update            # Update all plugins
:Mason                  # Open Mason LSP installer
```

### LSP Operations
```
grn                     # Rename symbol
gra                     # Code action
grr                     # Find references
grd                     # Go to definition
gri                     # Go to implementation
grt                     # Go to type definition
```

### File Operations
```
<leader>sf              # Search files
<leader>sg              # Live grep
<leader>e               # Toggle Neo-tree
<leader>E               # Toggle Neo-tree in current window
<leader>sH              # Search files from home directory
```

### Diagnostics
```
<leader>ii              # Toggle inline diagnostics
<leader>id              # Toggle all diagnostics
:DiagnosticsToggle      # Toggle diagnostics
:DiagnosticsToggleVirtualText  # Toggle virtual text
```

### Custom Commands
```
:W                      # Write with sudo (via vim-suda)
<leader>r               # Reload Neovim configuration
```

### Buffer Navigation
```
Shift+j                 # Next buffer
Shift+;                 # Previous buffer
```

## Testing and Linting

The configuration includes:
- nvim-lint for linting various file types
- conform.nvim for automatic formatting
- Language-specific tools installed via Mason

To run formatters manually:
```
<leader>f               # Format current buffer
```

## Language-Specific Features

### Go Development
- go.nvim plugin for enhanced Go support
- gopls LSP server with advanced analysis

### Scala Development  
- nvim-metals for Scala/sbt support
- Requires manual metals installation

### Web Development
- TypeScript, JavaScript, CSS, HTML support
- Prettier/prettierd for formatting
- ESLint for linting

### Python Development
- pyright LSP server
- Black/isort formatters available

## File Structure Notes

- Diagnostics are automatically disabled for markdown files
- Hidden files are visible in Neo-tree by default
- Global statusline is enabled for better visual consistency
- Uses tokyonight-night colorscheme with custom styling

## Dependencies

The configuration relies on external tools that should be installed:
- `make` (for telescope-fzf-native)
- Language servers are auto-installed via Mason
- Formatters and linters are auto-installed via mason-tool-installer

## Customization Notes

- The configuration uses space as leader key
- Nerd fonts are disabled by default (set `vim.g.have_nerd_font = false`)
- Custom movement keys may require adjustment period for new users
- All plugin configurations can be found in their respective files under `lua/custom/plugins/`