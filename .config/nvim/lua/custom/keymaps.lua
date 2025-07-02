-- Custom keymaps for Neovim configuration
-- This file contains all user-defined keymaps for better modularity.

-- Remap movement keys in visual and normal modes
vim.api.nvim_set_keymap('v', 'j', '<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'k', '<Down>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'l', '<Up>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', ';', '<Right>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'j', '<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', '<Down>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'l', '<Up>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ';', '<Right>', { noremap = true, silent = true })

-- Neo-tree keymaps
vim.api.nvim_set_keymap('n', '<leader>e', ':Neotree toggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>E', ':Neotree position=current toggle<CR>', { noremap = true, silent = true })

-- Buffer navigation keymaps
vim.api.nvim_set_keymap('n', '<S-j>', ':bnext<CR>', { noremap = true, silent = true }) -- Shift+j for next buffer
vim.api.nvim_set_keymap('n', '<S-;>', ':bprev<CR>', { noremap = true, silent = true }) -- Shift+; for previous buffer

-- -- Window movement keymaps (overriding default)
vim.keymap.set('n', '<C-j>', '<C-w>h', { desc = 'Move to window on the left' })
vim.keymap.set('n', '<C-k>', '<C-w>j', { desc = 'Move to window on the lower' })
vim.keymap.set('n', '<C-l>', '<C-w>k', { desc = 'Move to window on the upper' })
vim.keymap.set('n', '<C-;>', '<C-w>l', { desc = 'Move to window on the right' })

-- Reload Neovim configuration
vim.api.nvim_set_keymap('n', '<leader>r', ':luafile $MYVIMRC<CR>', { noremap = true, silent = true })

-- Inline diagnostics
-- Keybinding to toggle inline diagnostics (ii)
vim.api.nvim_set_keymap('n', '<Leader>ii', ':lua vim.cmd("DiagnosticsToggleVirtualText")<CR>', { noremap = true, silent = true })

-- Keybinding to toggle diagnostics (id)
vim.api.nvim_set_keymap('n', '<Leader>id', ':lua vim.cmd("DiagnosticsToggle")<CR>', { noremap = true, silent = true })

-- Telescope find files from home directory (no CWD restriction)
vim.keymap.set('n', '<leader>sH', function()
  require('telescope.builtin').find_files {
    prompt_title = 'Find Files (No CWD Restriction)',
    cwd = vim.fn.expand '~', -- Start from home, or use '/' for root
    hidden = true,
  }
end, { desc = '[S]earch files from [H]ome' })

vim.keymap.set('i', 'jj', '<ESC>', { silent = true })
vim.keymap.set('i', 'jk', '<ESC>', { silent = true })
