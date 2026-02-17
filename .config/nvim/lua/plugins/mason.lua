return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      if #vim.api.nvim_list_uis() == 0 then
        -- In headless mode, our bootstrap script handles installation directly
        -- via the registry API. Prevent LazyVim's config() from also installing.
        opts.ensure_installed = {}
      else
        vim.list_extend(opts.ensure_installed or {}, require("config.mason-tools"))
      end
    end,
  },
}
