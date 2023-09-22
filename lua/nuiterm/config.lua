local config = {}
config.defaults = {
  type = "buffer", -- or "editor" or "tab" or "window"
  show_on_send = true,
  focus_on_open = true,
  focus_on_send = false,
  open_at_cwd = false,
  terminal_win_fixed = true,
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
          top = "Terminal Menu",
          top_align = "center",
        },
      },
      win_options = {
        winhighlight = "Normal:Normal",
      }
    }
  }
}

return config
