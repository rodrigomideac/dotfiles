# Dotfiles

Personal dotfiles for a **niri** (scrollable-tiling Wayland compositor) setup on
Arch/Manjaro, deployed with [GNU Stow](https://www.gnu.org/software/stow/).

Stack: niri (WM) · waybar (bar) · fuzzel (launcher) · mako (notifications) ·
swaybg / swaylock / swayidle · kanshi (displays) · alacritty · zsh · neovim.

## Install

Automated (Debian/Ubuntu/Manjaro) — installs deps, clones to `~/.dotfiles`, stows
configs. See [`bootstrap/README.md`](bootstrap/README.md):

```bash
curl -fsSL https://raw.githubusercontent.com/rodrigomideac/dotfiles/master/bootstrap/bootstrap.sh | bash
```

Manual (Manjaro/Arch) — `./deps_v2.sh` installs the niri/Wayland stack via yay,
then `make stow` symlinks the configs. `stow` refuses to overlay existing files,
so clear conflicts in `~` / `~/.config` first.

## Make targets

| Target           | What it does                                             |
| ---------------- | ------------------------------------------------------- |
| `make stow`      | Symlink `.config`, `vim`, `zsh`, `scripts`, `tmux`      |
| `make stow-sudo` | Install systemd system services (power-profile, resume) |
| `make stow-work` | `make stow` plus the bash `.profile` (work machines)    |

## Notes

- **systemd user services** — after `make stow`: `systemctl --user daemon-reload`,
  then `enable --now` kanshi, solaar, swaybg, swayidle, ssh-agent.
- **Fonts** — needs a Nerd Font (waybar uses Iosevka Nerd Font), plus Noto Sans
  and Fira Code.
- **Kanshi** — find outputs with `niri msg outputs`, edit
  [`.config/kanshi/config`](.config/kanshi/config), `systemctl --user restart kanshi`.
- **Waybar** — `systemctl --user restart waybar` after edits; debug with
  `journalctl --user -u waybar -f`.
