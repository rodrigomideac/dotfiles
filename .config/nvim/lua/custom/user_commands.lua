-- Command to toggle inline diagnostics
vim.api.nvim_create_user_command('DiagnosticsToggleVirtualText', function()
  local current_value = vim.diagnostic.config().virtual_text
  if current_value then
    vim.diagnostic.config { virtual_text = false }
  else
    vim.diagnostic.config { virtual_text = true }
  end
end, {})

-- Command to toggle diagnostics
vim.api.nvim_create_user_command('DiagnosticsToggle', function()
  local current_value = vim.diagnostic.is_disabled()
  if current_value then
    vim.diagnostic.enable()
  else
    vim.diagnostic.disable()
  end
end, {})

vim.api.nvim_create_user_command('W', 'SudaWrite', {})

-- Autocommand for .md files
vim.api.nvim_create_autocmd('BufRead', {
  pattern = '*.md',
  callback = function()
    vim.diagnostic.enable(false)
  end,
})

-- Necessary for nvim-metals
vim.opt_global.shortmess:remove("F")
