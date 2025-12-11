return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      group_empty_dirs = true,
    },
    window = {
      mappings = {
        ["Z"] = "expand_all_subnodes",
      },
    },
  },
}
