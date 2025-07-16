-- Custom keymaps for Neovim configuration
-- This file contains all user-defined keymaps for better modularity.

-- Neo-tree keymaps
vim.api.nvim_set_keymap('n', '<leader>e', ':Neotree toggle<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>E', ':Neotree position=current toggle<CR>', { noremap = true, silent = true })

-- Buffer navigation keymaps
vim.api.nvim_set_keymap('n', '<S-h>', ':bnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<S-l>', ':bprev<CR>', { noremap = true, silent = true })

-- -- Window movement keymaps (overriding default)
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to window on the left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to window on the lower' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to window on the upper' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to window on the right' })
-- Move lines up/down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
-- Keep cursor centered when jumping
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Clear search highlighting
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Search and replace word under cursor
vim.keymap.set('n', '<leader>sR', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

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

-- Redirect change operations to the blackhole to avoid spoiling 'y' register content
vim.keymap.set('n', 'c', '"_c')
vim.keymap.set('n', 'C', '"_C')
