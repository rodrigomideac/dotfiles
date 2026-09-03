stow:
	stow --restow --target=${HOME}/.config .config
	stow --target=${HOME} vim
	stow --target=${HOME} zsh
	stow --no-folding --target=${HOME}/.local/bin scripts
	stow --no-folding --target=${HOME}/.local/share/applications applications
	stow --target=${HOME} tmux

# Compiled niri helpers (niri-cursor-pos) -> ~/.local/bin. Sources and the
# vendored Wayland protocol XML live in .config/niri/tools/; nothing built is
# committed.
tools:
	.config/niri/tools/build.sh

stow-sudo:
	sudo stow --no-folding --target=/etc/systemd/system systemd-services
	sudo systemctl enable root-resume
	sudo systemctl enable --now power-profile-switch.timer

stow-work: stow
	stow --target=${HOME} bash

# Install only the niri desktop environment (no CLI/dev toolchain, no config wipe)
desktop:
	bootstrap/lib/install-desktop.sh

