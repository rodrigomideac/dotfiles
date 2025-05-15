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

-- Window movement keymaps (overriding default)
vim.keymap.set('n', '<C-w>j', '<C-w>h', { desc = 'Move to window on the left' })
vim.keymap.set('n', '<C-w>k', '<C-w>j', { desc = 'Move to window on the lower' })
vim.keymap.set('n', '<C-w>l', '<C-w>k', { desc = 'Move to window on the upper' })
vim.keymap.set('n', '<C-w>;', '<C-w>l', { desc = 'Move to window on the right' })

-- Reload Neovim configuration
vim.api.nvim_set_keymap('n', '<leader>r', ':luafile $MYVIMRC<CR>', { noremap = true, silent = true })
