# Claude Instructions - Bootstrap System

## Architecture Overview

The bootstrap system uses **parallel package arrays** with cleanup keys for easy extension:

- `DEBIAN_PACKAGES` - Packages for Debian/Ubuntu (apt)
- `ARCH_PACKAGES` - Packages for Manjaro/Arch (pacman)
- `SPECIAL_PACKAGES` - Non-package-manager installs (oh-my-zsh, mise, atuin)

**Package format:** `"package_name:cleanup_key:description"`
- `package_name` - Package to install via package manager
- `cleanup_key` - Identifier for .zshrc cleanup (empty if no cleanup needed)
- `description` - User-friendly description shown in prompts

## How to Add New Packages

### Step 1: Add to Package Arrays

Edit `bootstrap/bootstrap.sh` around lines 20-30:

```bash
DEBIAN_PACKAGES=(
    "neovim::Neovim text editor"
    "build-essential::Build tools (gcc, make, etc.)"
    # ADD NEW PACKAGES HERE:
    "ripgrep:rg:Fast grep alternative"
)

ARCH_PACKAGES=(
    "neovim::Neovim text editor"
    "base-devel::Build tools (gcc, make, etc.)"
    # ADD NEW PACKAGES HERE (may have different name):
    "ripgrep:rg:Fast grep alternative"
)
```

**Important:** Package names may differ between distros:
- `build-essential` (Debian) = `base-devel` (Arch)
- Most packages have the same name on both

### Step 2: Add .zshrc Cleanup (If Needed)

If the package has initialization code in `.zshrc`, add cleanup logic in the `cleanup_zshrc()` function around line 330:

```bash
cleanup_zshrc() {
    local zshrc="$HOME/.zshrc"

    for cleanup_key in "${CLEANUP_KEYS[@]}"; do
        case "$cleanup_key" in
            # ... existing cases ...

            # ADD NEW CLEANUP HERE:
            rg)
                echo "  Removing ripgrep aliases..."
                sed -i '/alias rgf=/d' "$zshrc"
                ;;
        esac
    done
}
```

**Common patterns:**
- Remove specific lines: `sed -i '/pattern/d' "$zshrc"`
- Remove multiple patterns: `sed -i '/pattern1/d; /pattern2/d' "$zshrc"`
- Remove from plugins array: `sed -i 's/plugins=(\(.*\)plugin-name\(.*\))/plugins=(\1\2)/' "$zshrc"`

### Step 3: Test

```bash
# Test in Docker
make test

# Test interactively (skip the package to test cleanup)
./bootstrap.sh
# Choose "n" when prompted for your new package
# Verify references are removed: grep "pattern" ~/.zshrc
```

## Examples

### Example 1: Package with No .zshrc References

```bash
# In DEBIAN_PACKAGES and ARCH_PACKAGES:
"htop::System monitor"
#      ^^ Empty cleanup_key - no .zshrc cleanup needed
```

### Example 2: Package with .zshrc References

```bash
# In package arrays:
"fzf:fzf:Fuzzy finder"
#    ^^^ cleanup_key matches case in cleanup_zshrc()

# In cleanup_zshrc():
case "$cleanup_key" in
    fzf)
        echo "  Removing fzf keybindings..."
        sed -i '/source.*fzf\/key-bindings/d' "$zshrc"
        sed -i '/source.*fzf\/completion/d' "$zshrc"
        ;;
esac
```

### Example 3: Special Package (Non-Package-Manager)

```bash
# In SPECIAL_PACKAGES:
SPECIAL_PACKAGES=(
    "oh-my-zsh:oh-my-zsh:Oh My Zsh framework"
    "new-tool:new-tool:Description"
)

# In install_special_packages() function (around line 260):
case "$pkg" in
    new-tool)
        if [ -d "$HOME/.new-tool" ]; then
            log "New tool already installed, skipping"
        else
            log "Installing new tool..."
            # Custom installation commands here
            curl -fsSL https://example.com/install.sh | bash
        fi
        ;;
esac
```

## File Structure

```
bootstrap/
├── bootstrap.sh           # Main script (~320 lines)
├── Dockerfile.debian      # Debian 12 test container
├── assertions.sh          # Test validation
├── Makefile              # Test automation
├── README.md             # User documentation
└── CLAUDE.md             # This file
```

## Key Functions in bootstrap.sh

- **Lines 20-35:** Package arrays definition
- **Line 95:** `detect_sudo()` - Root/non-root detection
- **Line 100:** `install_core_deps()` - Install curl, git, zsh
- **Line 122:** `clone_dotfiles()` - Clone from GitHub
- **Line 140:** `select_packages_interactive()` - Prompt for each package
- **Line 218:** `install_packages()` - Install selected packages
- **Line 258:** `install_special_packages()` - Special package installation
- **Line 284:** `deploy_configs()` - Deploy .zshrc and nvim
- **Line 311:** `cleanup_zshrc()` - Remove uninstalled package references
- **Line 350:** `set_default_shell()` - Change to zsh
- **Line 374:** `main()` - Entry point

## Idempotency Notes

The script is designed to be idempotent (can run multiple times):
- Checks if packages already installed before installing
- Skips cloning if `~/.dotfiles` already exists
- Backs up existing configs with timestamps
- Won't reinstall oh-my-zsh if already present

## Testing Strategy

1. **Docker tests** - Automated testing on Debian 12
   - Runs as root (first install)
   - Runs as testuser (idempotency test)
   - Validates packages, configs, and .zshrc syntax

2. **Manual testing** - Test interactive mode
   - Run `./bootstrap.sh`
   - Skip various packages
   - Verify cleanup with `grep pattern ~/.zshrc`
