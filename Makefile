stow:
	stow --restow --target=${HOME}/.config .config
	stow --target=${HOME} vim
	stow --target=${HOME} zsh

stow-work: stow
	stow --target=${HOME} bash


