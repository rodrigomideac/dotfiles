return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      win = {
        input = {
          keys = {
            -- your custom keys if needed
          },
        },
        list = {
          wo = {
            wrap = true, -- Enable text wrapping
            linebreak = true, -- Break at word boundaries
          },
        },
      },
    },
  },
}
