return {
  name = "uv run python",
  condition = { filetype = "python" },
  builder = function()
    return {
      cmd = { "uv" },
      args = { "run", "python", vim.fn.expand("%:p") },
      components = { "default" },
    }
  end,
}
