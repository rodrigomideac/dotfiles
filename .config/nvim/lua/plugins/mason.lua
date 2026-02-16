return {
  {
    "mason-org/mason.nvim",
    dependencies = {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    cmd = {
      "MasonToolsInstall",
      "MasonToolsInstallSync",
      "MasonToolsUpdate",
      "MasonToolsUpdateSync",
      "MasonToolsClean",
    },
    opts = function()
      -- Disable run_on_start in headless mode to avoid race condition with Lazy sync
      local is_headless = #vim.api.nvim_list_uis() == 0
      return {
        ensure_installed = {
        -- LSP
        "clangd", -- C/C++ language server
        "docker-compose-language-service", -- Docker Compose language server
        "dockerfile-language-server", -- Dockerfile language server
        "gopls", -- Go language server
        "helm-ls", -- Helm language server
        "jdtls", -- Java language server
        "json-lsp", -- JSON language server
        "lua-language-server", -- Lua language server
        "marksman", -- Markdown language server
        "neocmakelsp", -- CMake language server
        "pyright", -- Python language server
        "ruff", -- Python linter/formatter (LSP)
        "taplo", -- TOML language server
        "vtsls", -- TypeScript/JavaScript language server
        "yaml-language-server", -- YAML language server

        -- Formatters
        "stylua", -- Lua formatter
        "shfmt", -- Shell formatter
        "prettier", -- JS/TS/JSON/YAML/MD formatter
        "black", -- Python formatter
        "isort", -- Python import sorter
        "gofumpt", -- Go formatter
        "goimports", -- Go imports organizer

        -- Linters
        "shellcheck", -- Shell linter
        "eslint_d", -- JS/TS linter (daemon)
        "golangci-lint", -- Go linter
        "markdownlint-cli2", -- Markdown linter
        "hadolint", -- Dockerfile linter
        "yamllint", -- YAML linter
        "cmakelang", -- CMake formatter/linter
        "cmakelint", -- CMake linter

        -- DAP
        "debugpy", -- Python debugger
        "delve", -- Go debugger
        "codelldb", -- Rust/C/C++ debugger
        "java-debug-adapter", -- Java debugger
        "java-test", -- Java test runner
        "js-debug-adapter", -- JS/TS debugger

        -- Tools
        "gitui", -- Git TUI
        "markdown-toc", -- Markdown TOC generator
      },
      auto_update = false,
      run_on_start = not is_headless,
      start_delay = 3000, -- 3 second delay to not slow startup
      debounce_hours = 24, -- Only check once per day
      integrations = {
        ["mason-lspconfig"] = true,
        ["mason-null-ls"] = true,
        ["mason-nvim-dap"] = true,
      },
      }
    end,
  },
}
