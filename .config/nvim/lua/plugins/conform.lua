return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      kotlin = { "ktlint" },
    },
    formatters = {
      ktlint = {
        -- Override for ktlint 0.42.1 compatibility
        -- (newer versions use --log-level=none which doesn't exist in 0.42.1)
        args = { "-F", "--stdin" },
        env = {
          JAVA_TOOL_OPTIONS = "--add-opens=java.base/java.lang=ALL-UNNAMED",
        },
      },
    },
  },
}
