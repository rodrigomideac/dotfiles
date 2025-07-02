return {
  'scalameta/nvim-metals',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'j-hui/fidget.nvim',
      opts = {},
    },
    {
      'mfussenegger/nvim-dap',
      config = function(self, opts)
        -- Debug settings if you're using nvim-dap
        local dap = require 'dap'

        dap.configurations.scala = {
          {
            type = 'scala',
            request = 'launch',
            name = 'RunOrTest',
            metals = {
              runType = 'runOrTestFile',
              --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
            },
          },
          {
            type = 'scala',
            request = 'launch',
            name = 'Test Target',
            metals = {
              runType = 'testTarget',
            },
          },
        }
      end,
    },
  },
  ft = { 'scala', 'sbt', 'java' },
  opts = function()
    local metals_config = require('metals').bare_config()
    metals_config.init_options.statusBarProvider = 'off'
    metals_config.settings = {
      showImplicitArguments = true,
      excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' },
      autoImportBuild = 'all',
      inlayHints = {
        {
          byNameParameters = { enable = true },
          hintsInPatternMatch = { enable = true },
          implicitArguments = { enable = true },
          implicitConversions = { enable = true },
          inferredTypes = { enable = true },
          typeParameters = { enable = true },
        },
      },
    }
    metals_config.capabilities = require('blink.cmp').get_lsp_capabilities()

    metals_config.on_attach = function(client, bufnr)
      -- if vim.bo.filetype == 'diff' then
      --   return
      -- end
      -- NOTE: Remember that Lua is a real programming language, and as such it is possible
      -- to define small helper and utility functions so you don't have to repeat yourself.
      --
      -- In this case, we create a function that lets us more easily define mappings specific
      -- for LSP related items. It sets the mode, buffer and description for us each time.
      local map = function(keys, func, desc, mode)
        mode = mode or 'n'
        vim.keymap.set(mode, keys, func, { desc = 'LSP: ' .. desc })
      end

      -- Rename the variable under your cursor.
      --  Most Language Servers support renaming across files, etc.

      map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

      -- Find references for the word under your cursor.
      map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

      -- Jump to the implementation of the word under your cursor.
      --  Useful when your language has ways of declaring types without an actual implementation.
      map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

      -- Jump to the definition of the word under your cursor.
      --  This is where a variable was first declared, or where a function is defined, etc.
      --  To jump back, press <C-t>.
      map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

      -- WARN: This is not Goto Definition, this is Goto Declaration.
      --  For example, in C this would take you to the header.
      map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

      -- Fuzzy find all the symbols in your current document.
      --  Symbols are things like variables, functions, types, etc.
      map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')

      -- Fuzzy find all the symbols in your current workspace.
      --  Similar to document symbols, except searches over your entire project.
      map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

      -- Jump to the type of the word under your cursor.
      --  Useful when you're not sure what type a variable is and you want to see
      --  the definition of its *type*, not where it was *defined*.
      map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')
    end

    return metals_config
  end,
  config = function(self, metals_config)
    local nvim_metals_group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
      pattern = self.ft,
      callback = function()
        require('metals').initialize_or_attach(metals_config)

        -- Force attachment after a short delay
        vim.defer_fn(function()
          local clients = vim.lsp.get_clients { name = 'metals' }
          if #clients > 0 then
            vim.lsp.buf_attach_client(0, clients[1].id)
          end
        end, 100)
      end,
      group = nvim_metals_group,
    })
  end,
}
