return {
  "folke/snacks.nvim",
  opts = {
    scroll = {
      animate = {
        duration = { step = 5, total = 50 },
        easing = "linear",
      },
      -- faster animation when repeating scroll after delay
      animate_repeat = {
        delay = 100, -- delay in ms before using the repeat animation
        duration = { step = 5, total = 50 },
        easing = "linear",
      },
    },
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
