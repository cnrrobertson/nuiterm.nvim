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
  show_on_send = true,
  focus_on_open = true,
  focus_on_send = false,
  -- Whether to use vim cwd for terminal directory
  open_at_cwd = false,
  -- Whether to only allow terminal buffer to use terminal window
  terminal_win_fixed = true,
  -- Whether to persist changes to terminal window size
  persist_size = true,
  -- Whether to hide terminal when leaving window
  hide_on_leave = false,
  keymaps = {},
  ui = {
    type = "split",
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
