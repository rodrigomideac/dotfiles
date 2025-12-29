-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--
-- -- Disable built-in spellchecking for Markdown
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("lazyvim_user_markdown", { clear = true }),
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.diagnostic.enable(false)
  end,
})

-- Enable wrap for all buffers related to dap
vim.api.nvim_create_autocmd("BufWinEnter", {
  pattern = "*",
  callback = function()
    if vim.bo.filetype:match("dap") then
      vim.wo.wrap = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local bufname = vim.api.nvim_buf_get_name(buf)
    local filetype = vim.bo[buf].filetype

    if filetype:match("dap") or bufname:match("dap") then
      print("DAP window opened - Buffer: " .. bufname .. ", Filetype: " .. filetype)
    end
  end,
})

vim.keymap.set("n", "<leader>dx", function()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local bufname = vim.api.nvim_buf_get_name(buf)
  local filetype = vim.bo[buf].filetype
  local buftype = vim.bo[buf].buftype

  print("Buffer: " .. bufname)
  print("Filetype: " .. filetype)
  print("Buftype: " .. buftype)
  print("Window: " .. win)
end, { desc = "Debug: Inspect current buffer/window" })

-- Makefile settings: use actual tabs instead of spaces
-- Use deferred execution to override any plugin settings
local function apply_makefile_settings()
  vim.defer_fn(function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 0
  end, 100)
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("lazyvim_user_makefile", { clear = true }),
  pattern = { "make", "makefile" },
  callback = apply_makefile_settings,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("lazyvim_user_makefile_buf", { clear = true }),
  pattern = { "Makefile", "makefile", "*.mk", "GNUmakefile" },
  callback = apply_makefile_settings,
})

-- Also apply on BufEnter to catch any late overrides
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("lazyvim_user_makefile_enter", { clear = true }),
  pattern = { "Makefile", "makefile", "*.mk", "GNUmakefile" },
  callback = apply_makefile_settings,
})
