---@tag Nuiterm.config
---@signature Nuiterm.config
---
---@text Plugin config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
--minidoc_replace_start Nuiterm.config = {
local config = {
  --minidoc_replace_end
  -- Default type of terminal
  -- could be "buffer", "window", "tab", or "editor"
  type = "buffer",
  -- Show terminal window (if hidden) when sending code
  show_on_send = true,
  -- Move cursor to terminal window when opening
  focus_on_open = true,
  -- Move cursor to terminal window when sending code
  focus_on_send = false,
  -- Use current buffer location for terminal directory (will use cwd otherwise)
  open_at_cur_buf = true,
  -- Only allow terminal buffer to use terminal window
  terminal_win_fixed = true,
  -- Persist changes to terminal window size
  persist_size = true,
  -- Hide terminal when leaving window
  hide_on_leave = false,
  -- Confirm exit when mounted terminals exist
  confirm_quit = true,
  -- Set insert mode on entering nuiterm terminal buffer
  insert_on_enter = true,
  -- Number of parent directories to show for buffers in terminal menu
  menu_buf_depth = 1,
  -- Confirm destruction of terminals
  menu_confirm_destroy = true,
  -- Keymaps for terminals (see nui.popup for more info)
  keymaps = {},
  ui = {
    -- Default ui type of terminal
    -- could be "split" or "popup"
    type = "split",
    -- Default layouts to cycle through (see nui.popup:update_layout)
    default_layouts = {
      split = {
        {relative = "editor", size = "40%", position = "right"},
        {relative = "editor", size = "40%", position = "bottom"},
      },
      popup = {
        {relative = "editor", size = "80%", position = "50%"},
        {relative = "editor", size = {height = "90%", width = "40%"},
          position = {col = "95%", row = "40%"}},
        {relative = "editor", size = {height = "40%", width = "40%"},
          position = {col = "95%", row = "10%"}},
      },
    },
    -- Default nui ui options
    nui_opts = {
      enter = true,
      focusable = true,
      border = {
        style = "rounded",
      },
    },
    -- Default terminal menu keybindings
    menu_keys = {
      focus_next = {"j", "<Down>", "<Tab>"},
      focus_prev = {"k", "<Up>", "<S-Tab>"},
      submit = {"<CR>", "<Space>"},
      close = {"<Esc>", "<C-c>", "q"},
      new = {"n"},
      destroy = {"d"},
      change_style = {"s"},
      change_layout = {"e"},
      toggle = {"w"},
      change_default_type = {"t"},
    },
    -- Default terminal menu popup ui options
    menu_opts = {
      relative = "editor",
      position = '50%',
      size = '50%',
      zindex = 500
    }
  }
}
--minidoc_afterlines_end

return config
