return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
  opts = {
    diff_binaries = false,
    enhanced_diff_hl = true,
    git_cmd = { "git" },
    use_icons = true,
    show_help_hints = true,
    watch_index = true,
    icons = {
      folder_closed = "",
      folder_open = "",
    },
    signs = {
      fold_closed = "",
      fold_open = "",
      done = "✓",
    },
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView Open" },
    { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "DiffView Close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "DiffView File History" },
    { "<leader>gr", "<cmd>DiffviewOpen master...HEAD<cr>", desc = "Review current branch vs master" },
  },
}