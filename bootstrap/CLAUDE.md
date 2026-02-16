# Claude Instructions - Bootstrap System

## Architecture Overview

The bootstrap system installs all dependencies, clones the repo to `~/.dotfiles`, and runs `make stow` to deploy configs via GNU Stow symlinks.

**No interactive prompts.** All packages are installed unconditionally. Desktop/visual tools (niri, alacritty, etc.) are listed in the summary for the user to install separately.

### Package arrays

- `DEBIAN_PACKAGES` - Packages for Debian/Ubuntu (apt)
- `ARCH_PACKAGES` - Packages for Manjaro/Arch (pacman)

**Package format:** `"package_name:description"`
- `package_name` - Package to install via package manager
- `description` - Human-readable description (for documentation only)

### Special packages

mise and atuin are installed via their official curl install scripts (not via package manager).

## How to Add New Packages

### System packages

Add to both arrays in `bootstrap/bootstrap.sh`:

```bash
DEBIAN_PACKAGES=(
    ...
    "new-pkg:Description of package"
)

ARCH_PACKAGES=(
    ...
    "new-pkg:Description of package"  # name may differ from Debian
)
```

**Important:** Package names may differ between distros:
- `build-essential` (Debian) = `base-devel` (Arch)
- Most packages have the same name on both

### Special packages (non-package-manager)

Add installation logic in `install_special_packages()`:

```bash
install_special_packages() {
    ...
    # new-tool
    log "Installing new-tool..."
    if command -v new-tool &>/dev/null; then
        log "new-tool already installed, skipping"
    else
        curl -fsSL https://example.com/install.sh | sh || log "Warning: Failed to install new-tool (non-fatal)"
    fi
}
```

### Stow conflicts

If the new package creates config files that stow needs to manage, add the paths to `prepare_stow_targets()` so they get removed before `make stow` runs.

## Main Flow

```
1. detect_distro          - Identify Debian/Ubuntu/Arch
2. detect_sudo            - Root vs sudo
3. clean_existing_configs - Remove ~/.dotfiles, ~/.oh-my-zsh, conflicting configs
4. install_core_deps      - curl, git, zsh, stow
5. install_ohmyzsh        - Oh My Zsh framework
6. install_neovim         - Neovim AppImage (>= 0.11)
7. clone_dotfiles         - Clone repo to ~/.dotfiles
8. install_packages       - All system packages in one call
9. install_special_packages - mise, atuin via curl
10. prepare_stow_targets  - mkdir -p dirs, remove conflicting files
11. make stow             - Deploy all configs as symlinks
12. set_default_shell     - chsh to zsh
13. print_summary         - What was done, what to install next
```

## File Structure

```
bootstrap/
├── bootstrap.sh           # Main script
├── Dockerfile.debian      # Debian 12 test container
├── assertions.sh          # Test validation
├── Makefile              # Test automation
├── README.md             # User documentation
└── CLAUDE.md             # This file
```

## Key Design Decisions

- **No interactive mode** - All packages install unconditionally. The `.zshrc` uses conditional checks (`command -v ... && ...`) for optional tools, so missing tools don't cause errors.
- **No .zshrc modification** - Stow symlinks the `.zshrc` from the repo directly. No `sed` cleanup needed.
- **No config copying** - `make stow` creates symlinks instead of copying files.
- **Special packages are non-fatal** - mise and atuin install failures log a warning but don't abort the script.
- **Desktop tools excluded** - Visual/desktop dependencies (niri, waybar, alacritty, etc.) are not installed by bootstrap. They're listed in the summary for manual installation.

## Testing

```bash
# Test in Docker
make test

# Verify stow works
make -C ~/.dotfiles stow
```
