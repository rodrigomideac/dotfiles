# Bootstrap

Automated dotfiles installation for Debian, Ubuntu, and Manjaro.

## Usage

**Remote installation (interactive):**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

**Remote installation (non-interactive, installs everything):**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash -s -- --no-interactive
```

**Local (after cloning):**
```bash
./bootstrap.sh                # Interactive - prompts for each package
./bootstrap.sh --no-interactive  # Installs all packages
```

## Testing

```bash
make test        # Run automated Docker tests
make debug-debian  # Interactive debugging
make clean       # Cleanup test images
```

## What it does

1. Installs core dependencies (curl, git, zsh, sudo)
2. Installs oh-my-zsh (always)
3. Installs neovim via AppImage (latest version)
4. Clones dotfiles from GitHub to ~/.dotfiles
5. Prompts for optional packages (build tools, fonts, etc.)
6. Deploys ~/.zshrc and ~/.config/nvim/
7. Sets up neovim plugins (Lazy, Mason, Treesitter)
8. Removes .zshrc references for skipped packages
9. Sets zsh as default shell
