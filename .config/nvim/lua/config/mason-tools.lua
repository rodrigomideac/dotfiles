-- Single source of truth for mason tools.
-- Used by both the plugin config (mason.lua) and bootstrap/install-mason-tools.lua.
return {
  -- LSP
  "clangd",
  "docker-compose-language-service",
  "dockerfile-language-server",
  "gopls",
  "helm-ls",
  "jdtls",
  "json-lsp",
  "kotlin-lsp",
  "lua-language-server",
  "marksman",
  "neocmakelsp",
  "pyright",
  "ruff",
  "taplo",
  "vtsls",
  "yaml-language-server",

  -- Formatters
  "stylua",
  "shfmt",
  "prettier",
  "black",
  "isort",
  "gofumpt",
  "goimports",

  -- Linters
  "shellcheck",
  "eslint_d",
  "golangci-lint",
  "markdownlint-cli2",
  "hadolint",
  "yamllint",
  "cmakelang",
  "cmakelint",

  -- DAP
  "debugpy",
  "delve",
  "codelldb",
  "java-debug-adapter",
  "java-test",
  "js-debug-adapter",

  -- Tools
  "gitui",
  "markdown-toc",
}
