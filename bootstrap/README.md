# Bootstrap

Automated dotfiles installation for Debian, Ubuntu, and Manjaro.

## Usage

**Remote installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

**Interactive mode (prompts for each package):**
```bash
./bootstrap.sh
```

**Non-interactive mode (installs all packages):**
```bash
./bootstrap.sh --no-interactive
```

## Testing

```bash
make test        # Run automated Docker tests
make debug-debian  # Interactive debugging
make clean       # Cleanup test images
```

## What it does

- Installs curl, git, zsh
- Clones dotfiles from GitHub
- Prompts for each package individually
- Deploys ~/.zshrc and ~/.config/nvim/
- Removes .zshrc references for uninstalled packages
- Sets zsh as default shell
