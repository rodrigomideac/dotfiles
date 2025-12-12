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

vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("i", "jk", "<Esc>")

vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Replace current word with clipboard content in whole buffer
vim.keymap.set("n", "<leader>rp", function()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end

  local clipboard = vim.fn.getreg("+")
  if clipboard == "" then
    vim.notify("Clipboard is empty", vim.log.levels.WARN)
    return
  end

  -- Escape special regex characters
  local escaped_word = vim.fn.escape(word, "/\\")
  local escaped_replacement = vim.fn.escape(clipboard, "/\\&~")

  -- Perform replacement using word boundaries
  local cmd = string.format("%%s/\\<%s\\>/%s/g", escaped_word, escaped_replacement)

  -- Execute and capture result
  local ok, result = pcall(vim.cmd, cmd)
  if ok then
    vim.notify("Success replacing")
  else
    vim.notify("Failed to perform replacement: " .. result, vim.log.levels.ERROR)
  end
end, { desc = "Replace current word with clipboard content in buffer" })

vim.keymap.set("n", "<leader>P", 'viw"_dP', { desc = "Replace word with register" })

-- Format buffer with Ctrl+Alt+L
vim.keymap.set({ "n", "x" }, "<C-A-l>", function()
  LazyVim.format({ force = true })
end, { desc = "Format buffer" })
