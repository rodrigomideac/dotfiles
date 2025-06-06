-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
--
-- local on_attach = function(client, bufnr)
--   local buf_map = function(mode, lhs, rhs, opts)
--     opts = opts or {}
--     opts.buffer = bufnr
--     vim.keymap.set(mode, lhs, rhs, opts)
--   end
--
--   buf_map('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
--   buf_map('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' }) -- Here
--   buf_map('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
--   buf_map('n', 'gr', vim.lsp.buf.implementation, { desc = 'Find references' })
--   buf_map('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
--   buf_map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostics' })
--   buf_map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
--   buf_map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
--   buf_map('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code actions' })
-- end
--
-- local lspconfig = require 'lspconfig'
--
-- lspconfig.gopls.setup {
--   on_attach = function(client, bufnr)
--     -- your on_attach code
--   end,
--   settings = {
--     gopls = {
--       analyses = {
--         unusedparams = true,
--         unreachable = true,
--       },
--       staticcheck = true,
--     },
--   },
-- }
-- {
--   'ray-x/go.nvim',
--   dependencies = { -- optional packages
--     'ray-x/guihua.lua',
--     'neovim/nvim-lspconfig',
--     'nvim-treesitter/nvim-treesitter',
--   },
--   config = function()
--     require('go').setup()
--   end,
--   event = { 'CmdlineEnter' },
--   ft = { 'go', 'gomod' },
--   build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
-- },
return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
    },
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false, -- Set to false to show hidden files
          hide_gitignored = false,
          hide_hidden = false,
        },
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
      },
    },
  },
  { 'akinsho/git-conflict.nvim', version = '*', config = true },
  { 'tpope/vim-fugitive' },
}
