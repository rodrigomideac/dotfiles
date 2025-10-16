This is a configuration for the neovim LazyVim IDE: <https://www.lazyvim.org/>

# Debug Process for Plugin Issues

## Checking Which Plugins Are Actually Installed

When plugin configuration isn't working, use these commands to debug:

### 1. Find installed plugins by pattern

```bash
find ~/.local/share/nvim/lazy -name "*cmp*" -type d
find ~/.local/share/nvim/lazy -name "*plugin-name*" -type d
```

### 2. Verify specific plugin installation

```bash
find ~/.local/share/nvim/lazy -name "nvim-cmp" -type d
find ~/.local/share/nvim/lazy -name "blink.cmp" -type d
```

### 3. List all installed plugins

```bash
ls ~/.local/share/nvim/lazy/
```

### 4. Check if configuration is being executed

Add debug notifications in your plugin config:

```lua
vim.notify("Plugin config loaded: " .. debug.getinfo(1, "S").source)
```

## Common Issues

- **LazyVim has switched default plugins**: Modern LazyVim uses blink.cmp instead of nvim-cmp
- **Plugin specs not loading**: Configuration file exists but plugin isn't installed
- **Multiple plugin specs conflict**: Check if multiple files configure the same plugin

## Key Locations

- Installed plugins: `~/.local/share/nvim/lazy/`
- LazyVim extras config: `lazyvim.json`
- Custom plugin configs: `lua/plugins/*.lua`

# CSS Module Navigation Setup

## Problem Solved

Custom CSS module navigation for TypeScript/React files where `gd` (go to definition) was incorrectly opening Next.js global type definitions instead of the corresponding `.module.css` file.

## Solution Implementation

Created `lua/plugins/css-modules.lua` with enhanced navigation that:

1. **Detects CSS module usage patterns**:
   - `styles.className` usage
   - `import ... from './file.module.css'` statements
   - Direct CSS class names

2. **Modern LazyVim compatibility**:
   - Works with `vtsls` (current TypeScript LSP)
   - Also supports legacy `tsserver` and `typescript-tools`
   - Uses proper filetype filtering for TS/JS/TSX/JSX files

3. **Keymap override strategy**:
   - `gd` - Enhanced go-to-definition (CSS modules aware, falls back to LSP)
   - `<leader>gc` - Dedicated CSS module navigation
   - Uses `vim.defer_fn()` to override LazyVim's default keymaps
   - Dual approach: LspAttach + FileType autocmds for reliability

## Key Technical Details

- **Timing issue**: LazyVim sets LSP keymaps after plugin autocmds run
- **Solution**: Use deferred keymap setting with 100-200ms delays
- **Pattern matching**: Multiple search patterns for camelCase/kebab-case conversion
- **Fallback behavior**: Gracefully falls back to normal LSP definition when not a CSS class

## Configuration Pattern for Custom LSP Keymaps

When overriding default LazyVim LSP keymaps, use this pattern:

```lua
vim.defer_fn(function()
  vim.keymap.set("n", "gd", custom_handler, {
    buffer = bufnr,
    remap = false,
    silent = true,
  })
end, 100)
```

# vtsls LSP Debugging Guide

## Problem: Missing Type Hints for Imported Functions

When TypeScript inlay hints work for built-in functions but not for imported functions from your project, the issue is typically in the vtsls inlay hint configuration.

## Debugging Steps

### 1. Enable LSP Logging
```lua
:lua vim.lsp.set_log_level('DEBUG')
```
Log location: `~/.local/state/nvim/lsp.log`

### 2. Check vtsls Configuration in Log
Look for the `workspace/didChangeConfiguration` message in lsp.log to see current settings:
```
typescript = { 
  inlayHints = { 
    parameterNames = { enabled = "literals" }  -- This is the problem!
  }
}
```

### 3. Common Configuration Issues

**Problem**: `parameterNames.enabled = "literals"` only shows hints for literal values
**Solution**: Change to `"all"` to show hints for all parameters including variables

**Problem**: `variableTypes.enabled = false` hides variable type hints
**Solution**: Set to `true` to show variable types

### 4. Fix vtsls Configuration

Create `lua/plugins/vtsls.lua`:
```lua
return {
  "yioneko/nvim-vtsls",
  opts = {
    settings = {
      typescript = {
        inlayHints = {
          parameterNames = {
            enabled = "all", -- "all" | "literals" | "none"
            suppressWhenArgumentMatchesName = false,
          },
          parameterTypes = { enabled = true },
          variableTypes = { enabled = true },
          functionLikeReturnTypes = { enabled = true },
        },
      },
    },
  },
}
```

### 5. Verification Commands
```vim
:LspInfo              # Check server capabilities
:LspRestart vtsls     # Restart after config changes
```

## Key Insight
The log shows `inlayHintProvider = true` but actual hint generation depends on specific typescript.inlayHints settings. LazyVim's default `"literals"` setting is too restrictive for imported functions.
