return {
  "scalameta/nvim-metals",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = function()
    local metals_config = require("metals").bare_config()

    metals_config.init_options.statusBarProvider = "off"

    metals_config.settings = {
      javaHome = "/home/rodrigo/.local/share/mise/installs/java/temurin-11.0.29+7",
    }

    metals_config.on_attach = function(client, bufnr)
      -- your on_attach function
      require("metals").setup_dap()
    end

    return metals_config
  end,
}
