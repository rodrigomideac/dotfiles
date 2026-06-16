stow:
	stow --restow --target=${HOME}/.config .config
	stow --target=${HOME} vim
	stow --target=${HOME} zsh
	stow --no-folding --target=${HOME}/.local/bin scripts
	stow --target=${HOME} tmux

stow-sudo:
	sudo stow --no-folding --target=/etc/systemd/system systemd-services
	sudo systemctl enable root-resume
	sudo systemctl enable --now power-profile-switch.timer

stow-work: stow
	stow --target=${HOME} bash

