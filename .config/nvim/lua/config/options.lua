-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable autoformat on save
vim.g.autoformat = false

-- Force LazyVim to always use telescope (not snacks picker)
vim.g.lazyvim_picker = "telescope"

-- Fix yank/paste over SSH+tmux: OSC 52 sends yanked text to the host's
-- system clipboard (so Ctrl+Shift+V works), and paste reads from tmux buffer
-- (so prefix+] and p in neovim also work).
if os.getenv("TMUX") then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "osc52-tmux",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = { "tmux", "save-buffer", "-" },
      ["*"] = { "tmux", "save-buffer", "-" },
    },
    cache_enabled = false,
  }
  vim.opt.clipboard = "unnamedplus"
end
