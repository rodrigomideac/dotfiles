-- diffview builds its cmdline completion candidates with
-- `vec_push(candidates, unpack(list))`. In a repo with thousands of refs that
-- blows LuaJIT's unpack limit and every completion attempt dies with:
--   E5108: ... diffview/init.lua:213: too many results to unpack
-- Upstream has been dormant since 2024-06, so swap the two affected completers
-- for copies that append in a loop. If these ever drift out of sync with the
-- plugin they fall back to the originals.
local function extend(dst, src)
  for i = 1, #src do
    dst[#dst + 1] = src[i]
  end

  return dst
end

local fixed_completers = {
  DiffviewOpen = function(ctx)
    local adapter = require("diffview").get_adapter()
    local has_rev_arg = false
    local candidates = {}

    for i = 2, math.min(#ctx.args, ctx.divideridx) do
      if ctx.args[i]:sub(1, 1) ~= "-" and i ~= ctx.argidx then
        has_rev_arg = true
        break
      end
    end

    if ctx.argidx > ctx.divideridx then
      if adapter then
        extend(candidates, adapter:path_candidates(ctx.arg_lead))
      else
        extend(candidates, vim.fn.getcompletion(ctx.arg_lead, "file", 0))
      end
    elseif adapter then
      if not has_rev_arg and ctx.arg_lead:sub(1, 1) ~= "-" then
        extend(candidates, adapter.comp.open:get_all_names())
        extend(candidates, adapter:rev_candidates(ctx.arg_lead, { accept_range = true }))
      else
        extend(candidates, adapter.comp.open:get_completion(ctx.arg_lead) or adapter.comp.open:get_all_names())
      end
    end

    return candidates
  end,

  DiffviewFileHistory = function(ctx)
    local adapter = require("diffview").get_adapter()
    local candidates = {}

    if adapter then
      extend(
        candidates,
        adapter.comp.file_history:get_completion(ctx.arg_lead) or adapter.comp.file_history:get_all_names()
      )
      extend(candidates, adapter:path_candidates(ctx.arg_lead))
    else
      extend(candidates, vim.fn.getcompletion(ctx.arg_lead, "file", 0))
    end

    return candidates
  end,
}

local function patch_completers()
  local diffview = require("diffview")

  for name, fixed in pairs(fixed_completers) do
    local original = diffview.completers[name]

    diffview.completers[name] = function(ctx)
      local ok, candidates = pcall(fixed, ctx)
      if ok then
        return candidates
      end

      ok, candidates = pcall(original, ctx)

      return ok and candidates or {}
    end
  end
end

return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
  opts = {
    diff_binaries = false,
    enhanced_diff_hl = true,
    git_cmd = { "git" },
    use_icons = true,
    show_help_hints = true,
    watch_index = true,
    icons = {
      folder_closed = "",
      folder_open = "",
    },
    signs = {
      fold_closed = "",
      fold_open = "",
      done = "✓",
    },
  },
  config = function(_, opts)
    require("diffview").setup(opts)
    patch_completers()
  end,
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView Open" },
    { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "DiffView Close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "DiffView File History" },
    { "<leader>gr", "<cmd>DiffviewOpen master...HEAD<cr>", desc = "Review current branch vs master" },
  },
}
