return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden", -- Include dotfiles and hidden files
        "--glob=!.git/", -- Exclude .git directory
        "--glob=!.metals/", -- Exclude Scala metals directory
        "--glob=!.bloop/", -- Exclude Bloop build directory
        "--glob=!target/", -- Exclude Bloop build directory
      },
      layout_strategy = "vertical", -- Stack panels vertically
      layout_config = {
        vertical = {
          preview_height = 0.5, -- Preview takes 50% of height (adjust 0.3-0.6)
          mirror = false, -- false = preview at bottom, true = preview at top
        },
      },
    },
    pickers = {
      find_files = {
        hidden = true, -- Include hidden files
        no_ignore = true, -- Include gitignored files
        find_command = {
          "rg",
          "--files",
          "--hidden",
          "--glob=!.git/",
          "--glob=!.metals/",
          "--glob=!.bloop/",
          "--glob=!target/", -- Exclude Bloop build directory
          "--glob=!node_modules/",
          "--glob=!.mastra/",
        },
      },
    },
  },
  keys = {
    {
      "<leader><leader>",
      function()
        LazyVim.pick("find_files", { hidden = true, no_ignore = true })()
      end,
      desc = "Find files (including hidden and gitignored)",
    },
  },
}
