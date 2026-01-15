clean:
	rm -rf ~/.local/share/nvim
	rm -rf ~/.local/state/nvim
	rm -rf ~/.cache/nvim

install:
	nvim --headless -c 'lua vim.api.nvim_create_autocmd("User", { pattern = "MasonToolsUpdateCompleted", callback = function() vim.cmd("quitall") end })' '+MasonToolsUpdateSync'
