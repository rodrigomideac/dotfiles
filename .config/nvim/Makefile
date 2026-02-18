SCRIPTS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))scripts

.PHONY: clean configure mason-debug

clean:
	rm -rf ~/.local/share/nvim
	rm -rf ~/.local/state/nvim
	rm -rf ~/.cache/nvim

configure: clean
	nvim --headless "+Lazy! sync" +qa
	nvim --headless +"luafile $(SCRIPTS_DIR)/install-mason-tools.lua"

mason-debug:
	rm -rf ~/.local/share/nvim/mason
	nvim --headless +"luafile $(SCRIPTS_DIR)/install-mason-tools.lua"
