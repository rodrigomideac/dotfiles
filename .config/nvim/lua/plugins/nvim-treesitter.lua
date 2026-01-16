return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- Use pre-built parser binaries instead of compiling locally
    -- This avoids GLIBC version mismatch errors with tree-sitter CLI
    prefer_git = false,
  },
}
