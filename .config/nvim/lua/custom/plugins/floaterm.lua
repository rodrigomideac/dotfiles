return {
  'voldikss/vim-floaterm', -- or 'kassio/neoterm' for neoterm
  config = function()
    -- Set up key mappings here
    vim.api.nvim_set_keymap('n', '<leader>ft', ':FloatermToggle<CR>', { noremap = true, silent = true })
  end,
}
