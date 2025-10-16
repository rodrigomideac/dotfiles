return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Disable Kotlin LSP (performance issues on large projects)
      kotlin_language_server = {
        autostart = false,
      },
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
