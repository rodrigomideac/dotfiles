-- Collapse/restore the left ("old"/base) window of an Octo review diff, so the
-- new side gets the full width. The window is kept alive at minimum width rather
-- than closed, because Layout:ensure_layout() re-splits a closed one on the next
-- file switch.
local function toggle_base_pane()
  local reviews = package.loaded["octo.reviews"]
  local layout = reviews and reviews.get_current_layout()

  if not layout or not vim.api.nvim_win_is_valid(layout.left_winid) then
    vim.notify("Not in an Octo review layout", vim.log.levels.WARN)
    return
  end

  if layout.user_base_hidden then
    vim.api.nvim_win_set_width(layout.left_winid, layout.user_base_width)
    layout.user_base_hidden = false
  else
    -- don't collapse the window the cursor is sitting in
    if vim.api.nvim_get_current_win() == layout.left_winid and vim.api.nvim_win_is_valid(layout.right_winid) then
      vim.api.nvim_set_current_win(layout.right_winid)
    end

    layout.user_base_width = vim.api.nvim_win_get_width(layout.left_winid)
    vim.api.nvim_win_set_width(layout.left_winid, 0) -- clamped to 'winminwidth'
    layout.user_base_hidden = true
  end
end

return {
  {
    "pwntester/octo.nvim",
    opts = {
      -- The LazyVim extra turns this on, but it makes every issue/PR query embed
      -- ProjectV2 timeline fragments, which GitHub rejects unless the gh token
      -- carries `read:project`. Off = PR review works with a plain `repo` token.
      -- To use Projects v2 instead: `gh auth refresh -s read:project` and drop this.
      default_to_projects_v2 = false,
    },
    init = function()
      -- Octo's review diff buffers take their filetype from the reviewed file, so
      -- there is no `ft` to hang a keymap off. Bind per buffer once a window of
      -- the review layout is entered instead.
      vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
        group = vim.api.nvim_create_augroup("user_octo_review_keys", { clear = true }),
        callback = function(args)
          local reviews = package.loaded["octo.reviews"]
          local layout = reviews and reviews.get_current_layout()
          if not layout then
            return
          end

          local win = vim.api.nvim_get_current_win()
          local panel = layout.file_panel
          if win ~= layout.left_winid and win ~= layout.right_winid and win ~= (panel and panel.winid) then
            return
          end

          vim.keymap.set("n", "<localleader>o", toggle_base_pane, {
            buffer = args.buf,
            silent = true,
            desc = "Toggle old/base diff pane (Octo)",
          })
        end,
      })
    end,
  },
}
