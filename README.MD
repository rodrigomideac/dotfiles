# Dotfiles

Personal dotfiles for a **niri** (scrollable-tiling Wayland compositor) setup on
Debian/Ubuntu (incl. Kubuntu) or Arch/Manjaro, deployed with
[GNU Stow](https://www.gnu.org/software/stow/).

Stack: niri (WM) · waybar (bar) · fuzzel (launcher) · mako (notifications) ·
swaybg / swaylock / swayidle · kanshi (displays) · alacritty · zsh · neovim.

## Install

### Fresh machine — one command (Debian/Ubuntu/Manjaro)

```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

This is the **whole** setup: it clones the repo to `~/.dotfiles`, installs
dependencies, runs `make stow`, sets up zsh + neovim, and then interactively
offers to install the niri desktop stack. There is **nothing to run
afterward** — `make stow` is already done for you.

To install the niri desktop without the prompt, pass `--desktop`:

```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash -s -- --desktop
```

See [`bootstrap/README.md`](bootstrap/README.md) for all flags.

### Manual (Arch/Manjaro)

`./deps_v2.sh` installs the niri/Wayland stack via yay, then `make stow`
symlinks the configs. `stow` refuses to overlay existing files, so clear
conflicts in `~` / `~/.config` first.

## Make targets

| Target           | What it does                                             |
| ---------------- | ------------------------------------------------------- |
| `make stow`      | Symlink `.config`, `vim`, `zsh`, `scripts`, `tmux` (re-run after editing a config) |
| `make stow-sudo` | Install systemd system services (power-profile, resume) |
| `make stow-work` | `make stow` plus the bash `.profile` (work machines)    |

## Notes

- **systemd user services** — the desktop services (kanshi, mako, solaar, swaybg,
  swayidle, waybar) are enabled automatically by the `niri.service.wants/` symlinks
  stow deploys and start with the niri session; just run
  `systemctl --user daemon-reload` after `make stow`. Enable standalone ones (e.g.
  `ssh-agent`) with `systemctl --user enable --now <name>`.
- **Fonts** — needs a Nerd Font (waybar uses Iosevka Nerd Font), plus Noto Sans
  and Fira Code.
- **Kanshi** — find outputs with `niri msg outputs`, edit
  [`.config/kanshi/config`](.config/kanshi/config), `systemctl --user restart kanshi`.
- **Waybar** — `systemctl --user restart waybar` after edits; debug with
  `journalctl --user -u waybar -f`.
