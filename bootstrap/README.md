# Bootstrap

Automated dotfiles installation for Debian, Ubuntu, and Manjaro/Arch.

Installs all dependencies, clones the repo to `~/.dotfiles`, and deploys configs via `make stow` (GNU Stow symlinks).

## Usage

**Remote installation (one-liner):**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```
