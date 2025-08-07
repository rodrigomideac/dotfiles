-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
-- Add to your keymaps or in the neotest config
vim.keymap.set("n", "<leader>to", function()
  require("neotest").output.open({ enter = true })
  vim.schedule(function()
    vim.cmd("normal! G")
  end)
end, { desc = "Open test output and scroll to end" })

vim.cmd("cmap w!! w !sudo tee > /dev/null %")
