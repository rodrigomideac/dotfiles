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
        "markdownlint-cli2", -- Markdown linter
        "hadolint", -- Dockerfile linter
        "yamllint", -- YAML linter

        -- DAP
        "debugpy", -- Python debugger
        "delve", -- Go debugger
        "codelldb", -- Rust/C/C++ debugger
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
