stow:
	stow --restow --target=${HOME}/.config .config
	stow --target=${HOME} vim
	stow --target=${HOME} imwheel
	stow --target=${HOME} zsh
	stow --target=${HOME} keyboard_layouts
	stow --no-folding --target=${HOME}/.local/bin scripts

stow-sudo:
	sudo stow --no-folding --target=/etc/systemd/system systemd-services
	sudo systemctl enable root-resume

stow-work: stow
	stow --target=${HOME} bash

