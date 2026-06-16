# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

Personal dotfiles for a **niri** (scrollable-tiling Wayland compositor) desktop on
Arch/Manjaro. Configs are deployed as symlinks with **GNU Stow**, so editing a file
in this repo edits the live config.

The repo lives at `~/.dotfiles`. `make stow` symlinks it into `~` and `~/.config`.

## Layout

- `.config/` — stowed into `~/.config` (niri, waybar, kanshi, nvim, alacritty, …)
- `scripts/` — stowed into `~/.local/bin`
- `vim/`, `zsh/`, `tmux/`, `bash/` — dotfiles stowed into `~`
- `systemd-services/` — system-level units (`make stow-sudo`)
- `bootstrap/` — automated installer for a fresh Debian/Ubuntu/Manjaro machine
- `deps_v2.sh` — Manjaro/Arch dependency installer (yay)

## Desktop stack

niri (WM) · waybar (bar) · fuzzel (launcher) · mako (notifications) ·
swaybg (wallpaper) · swaylock/swayidle (lock/idle) · kanshi (display config) ·
alacritty · zsh · neovim. This is a pure **Wayland** setup — there is no X11
window manager here.

## Applying changes

```bash
make stow          # re-symlink everything
make stow-sudo     # systemd system services (needs sudo)
make stow-work     # stow + bash .profile (work machines)
```

Restart the affected service after editing its config, e.g.
`systemctl --user restart waybar` (likewise `kanshi`). Reload niri config with
`niri msg action ...` — niri picks up most `config.kdl` changes on save.

## Per-tool guidance

Some directories have their own `CLAUDE.md` with deeper notes — read it before
working there:

- `.config/niri/CLAUDE.md` — niri config and IPC
- `.config/kanshi/CLAUDE.md` — monitor configuration
- `.config/nvim/CLAUDE.md` — Neovim config
