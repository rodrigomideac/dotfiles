return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      signature = { enabled = false },
    },
    -- Disable blend/transparency which can cause invisible floating windows in tmux
    views = {
      mini = {
        win_options = { winblend = 0 },
      },
      popup = {
        win_options = { winblend = 0 },
      },
      notify = {
        win_options = { winblend = 0 },
      },
    },
    commands = {
      history = {
        filter = {
          any = {
            { event = "notify" },
            { error = true },
            { warning = true },
            { event = "msg_show", kind = { "", "echo", "echomsg", "lua_print", "list_cmd" } },
            { event = "lsp", kind = "message" },
          },
        },
      },
    },
  },
}
