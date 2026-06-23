# Bootstrap

Automated dotfiles installation for Debian, Ubuntu, and Manjaro/Arch.

Installs all dependencies, clones the repo to `~/.dotfiles`, and deploys configs via `make stow` (GNU Stow symlinks).

## Usage

**Remote installation (one-liner):**
```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

## Desktop environment (opt-in)

By default the script installs only the CLI/dev toolchain. At the end it asks
whether to also install the **niri desktop environment** — the compositor plus
the full companion stack: `niri`, `waybar`, `fuzzel`, `mako`, `swaylock`,
`swayidle`, `swaybg`, `kanshi`, `alacritty`, `xwayland-satellite`,
`wl-clipboard`, `cliphist`, `grim`, `slurp`, and the GNOME/GTK XDG portals.

Most packages come from the official repos (Ubuntu `universe`, Arch `extra`) —
no AUR/yay required. The exceptions are `niri` and `xwayland-satellite`, which
are not in Ubuntu's default archive: on Ubuntu the script adds the
`ppa:avengemedia/danklinux` PPA (idempotently) before installing. On Arch all
of it, niri included, is in `extra`.

Skip the prompt with a flag:

```bash
~/.dotfiles/bootstrap/bootstrap.sh --desktop      # install it, no prompt
~/.dotfiles/bootstrap/bootstrap.sh --no-desktop   # skip it, no prompt
```

A non-interactive run (e.g. `curl | bash` with no TTY) installs the desktop
only when `--desktop` is passed. A display manager and a browser are
intentionally left out — install those to taste.

### Install only the desktop stack

To install *just* the desktop environment — no CLI/dev toolchain, no config
wipe, no oh-my-zsh/neovim — run the standalone installer directly:

```bash
~/.dotfiles/bootstrap/lib/install-desktop.sh
# or, from the repo root:
make desktop
```

This is the same code path `bootstrap.sh` uses (same package list, same niri
PPA handling), just on its own. It's idempotent — already-installed packages
and an already-configured PPA are skipped.
