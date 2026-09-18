return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- kotlin.nvim owns this server: it registers `kotlin_lsp` with the
      -- versioned mason binary, --system-path, jvm_args, inlay-hint settings
      -- and its own handlers. nvim-lspconfig also ships a stock `kotlin_lsp`
      -- (cmd = { "intellij-server", "--stdio" }) which mason-lspconfig would
      -- auto-enable; whichever registration wins the FileType race decides the
      -- client, so kotlin.nvim's config was being dropped at random. Disabling
      -- it here only stops the automatic enable — kotlin.nvim still starts it.
      kotlin_lsp = { enabled = false },
      vtsls = {
        settings = {
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = true },
            },
          },
        },
      },
    },
  },
}
