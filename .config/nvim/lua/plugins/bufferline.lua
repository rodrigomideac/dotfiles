return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      -- -- Show full file path in tabs
      -- name_formatter = function(buf)
      --   -- Get the full path relative to cwd
      --   return vim.fn.fnamemodify(buf.path, ":~:.")
      -- end,
      -- Allow long tab names
      -- max_name_length = 999, -- Increase maximum name length
      -- tab_size = 999, -- Allow tabs to grow as needed
      truncate_names = false, -- Don't truncate names
    },
  },
  keys = {
    { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
    { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
  },
}
