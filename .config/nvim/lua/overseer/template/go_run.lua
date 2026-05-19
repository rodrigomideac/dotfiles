return {
  name = "go run (package)",
  condition = { filetype = "go" },
  builder = function()
    return {
      cmd = { "go" },
      args = { "run", "." },
      cwd = vim.fn.expand("%:p:h"),
      components = { "default" },
    }
  end,
}
