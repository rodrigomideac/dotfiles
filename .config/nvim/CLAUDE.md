This is a configuration for the neovim LazyVim IDE: https://www.lazyvim.org/

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


