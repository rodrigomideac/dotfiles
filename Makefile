stow:
	stow --restow --target=${HOME}/.config .config
	stow --target=${HOME} vim
	stow --target=${HOME} imwheel
	stow --target=${HOME} zsh
	stow --no-folding --target=${HOME}/.local/bin scripts

stow-work: stow
	stow --target=${HOME} bash


