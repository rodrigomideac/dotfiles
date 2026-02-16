# Bootstrap

Automated dotfiles installation for Debian, Ubuntu, and Manjaro/Arch.

Installs all dependencies, clones the repo to `~/.dotfiles`, and deploys configs via `make stow` (GNU Stow symlinks).

## Usage

**Remote installation (one-liner):**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

**Local (after cloning):**
```bash
./bootstrap.sh
```

**Custom repo URL** (local path, fork, SSH, etc.):
```bash
DOTFILES_REPO_URL=/path/to/local/repo ./bootstrap.sh
DOTFILES_REPO_URL=git@github.com:user/dotfiles.git ./bootstrap.sh
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_REPO_URL` | `https://github.com/rodrigomideac/dotfiles.git` | Git URL to clone dotfiles from. Supports any git-compatible URL (https, ssh, local path). |

## What it does

1. Installs core dependencies (curl, git, zsh, stow, sudo)
2. Installs Oh My Zsh
3. Installs Neovim via AppImage (>= 0.11)
4. Clones dotfiles to `~/.dotfiles`
5. Installs system packages (build tools, fonts, tmux, ripgrep, jq, zoxide, etc.)
6. Installs mise and atuin via their official install scripts
7. Deploys all configs via `make stow` (symlinks)
8. Sets zsh as default shell

## After bootstrap

Desktop/visual tools (niri, alacritty, waybar, etc.) are **not** installed by bootstrap. Install them separately for your environment.

Additional make targets:
```bash
make stow-sudo   # Deploy systemd services (requires sudo)
make stow-work   # Deploy bash .profile config (work environments)
```

## Testing

```bash
make test          # Run automated Docker tests
make test-verbose  # Verbose build output
make debug-debian  # Interactive debugging shell
make clean         # Cleanup test images
```
