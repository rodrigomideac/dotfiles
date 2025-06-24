return {
  {
    'antosha417/nvim-lsp-file-operations',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neo-tree/neo-tree.nvim',
    },
    config = function()
      require('lsp-file-operations').setup()
    end,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
      -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false, -- neo-tree will lazily load itself
    ---@module "neo-tree"
    ---@type neotree.Config?
    config = function()
      vim.diagnostic.config {
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.INFO] = '',
            [vim.diagnostic.severity.HINT] = '󰌵',
          },
        },
      }

      require('neo-tree').setup {
        close_if_last_window = true, -- Close Neo-tree if it is the last window
        popup_border_style = 'rounded',
        enable_git_status = true,
        enable_diagnostics = true,
        filesystem = {

          filtered_items = {
            visible = true,
            show_hidden_count = true,
            hide_dotfiles = false,
            hide_gitignored = true,
            hide_by_name = {
              -- add extension names you want to explicitly exclude
              '.git',
              -- '.DS_Store',
              -- 'thumbs.db',
            },
            never_show = {},
          },
          follow_current_file = {
            enabled = true,
          }, -- Focus the f:hile in the tree when opened
          use_libuv_file_watcher = true,
        },
        window = {
          position = 'left',
          width = 30,
          mappings = {
            ['j'] = 'noop',
            ['k'] = 'noop',
            ['l'] = 'noop',
            [';'] = 'noop',
            [''] = 'noop',
            ['<space>'] = 'noop',
          },
        },
      }
      vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal left<CR>', {})
    end,
  },
}
