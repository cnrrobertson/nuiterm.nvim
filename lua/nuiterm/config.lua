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
  -- Use vim cwd for terminal directory
  open_at_cwd = false,
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
  keymaps = {},
  ui = {
    -- Default ui type of terminal
    -- could be "split" or "popup"
    type = "split",
    -- Default split ui options
    split_opts = {
      enter = true,
      focusable = true,
      border = {
        style = "rounded",
      },
      position = "right",
      size = "40%",
      relative = "editor",
    },
    -- Default popup ui options
    popup_opts = {
      enter = true,
      focusable = true,
      border = {
        style = "rounded",
      },
      position = "50%",
      size = {
        width = "80%",
        height = "80%"
      },
      relative = "editor",
    },
    -- Default terminal menu popup ui options
    menu_opts = {
      relative = "editor",
      position = '50%',
      size = '50%',
      border = {
        style = "rounded",
        text = {
          top = "Terminals",
          top_align = "center",
          bottom = "j=down  k=up  q=exit  d=destroy  (* denotes active terminal)",
          bottom_align = "left",
        },
      },
      win_options = {
        winhighlight = "Normal:Normal",
      }
    }
  }
}
--minidoc_afterlines_end

return config
