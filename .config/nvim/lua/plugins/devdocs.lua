return {
  "luckasRanarison/nvim-devdocs",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "DevdocsOpen", "DevdocsOpenFloat", "DevdocsInstall", "DevdocsFetch", "DevdocsToggle" },
  keys = {
    { "<leader>od", "<cmd>DevdocsOpenFloat python-3.12<cr>", desc = "Python docs" },
  },
  opts = {
    float_win = {
      relative = "editor",
      height = 40,
      width = 120,
      border = "rounded",
    },
    after_open = function(bufnr)
      vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = bufnr, silent = true })
    end,
  },
}
