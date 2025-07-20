return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    -- bigfile = { enabled = true },
    dashboard = { enabled = true },
    -- explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    -- notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    ---@type snacks.scroll.Config
    scroll = {
      enabled = true,
      animate = {
        duration = { step = 45, total = 90 },
        easing = 'inOutQuad',
      },
      animate_repeat = {
        delay = 100,
        duration = { step = 5, total = 50 },
        easing = 'inOutQuad',
      },
    },
    statuscolumn = { enabled = true },
    words = { enabled = true },
  },
}
