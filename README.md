# nuiterm.nvim


Nuiterm provides an easy way to toggle and send code to terminals which are local to your buffer, window, tab, or editor.

The key design motivation for this plugin was to connect a REPL to each file buffer rather than having a single REPL for all buffers or each filetype.
With this, it mimics the experience of using [Jupyter Interactive windows](https://code.visualstudio.com/docs/python/jupyter-support-py) in VSCode.
The UI is all done with [nui.nvim](https://github.com/MunifTanjim/nui.nvim) to allow for ease of use and expansion.

Some features of the nuiterm:

    - Toggle a split/floating terminal for each buffer/window/tab
    - Toggle any number of global/editor terminals
    - Send commands, lines from the buffer, or visual selections to any terminal
    - Quickly toggle/delete terminals from a popup menu (or with telescope - see [Telescope integration](#telescope-integration))
    - Easily create and toggle task-specific terminals (such as for [lazygit](https://github.com/jesseduffield/lazygit) or [btop](https://github.com/aristocratos/btop))

Some oddities about the `nuiterm` (that may change in the future):

    - Only display one terminal at a time

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "cnrrobertson/nuiterm.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    -- "nvim-telescope/telescope.nvim", -- optional: for telescope toggling
  },
  config = function()
    require("nuiterm").setup()
    -- Toggle terminal of default type
    vim.keymap.set({'n','t'},'<c-n>',Nuiterm.toggle)
    -- (For buffer-type terminals) show connected buffer in window 1
    vim.keymap.set({'n','t'},'<c-p>',Nuiterm.focus_buffer_for_terminal)
    -- Toggle a global terminal number 1
    vim.keymap.set('n','<leader>tt',function()Nuiterm.toggle("editor",1)end)
    -- Toggle a new global terminal
    vim.keymap.set('n','<leader>tn',function()Nuiterm.toggle("editor",-1)end)

    -- Toggle terminal menu
    vim.keymap.set('n','<leader>tm',Nuiterm.toggle_menu)
    vim.keymap.set('n','<leader>ft',require('nuiterm.telescope').picker)
  end,
}
```
After `setup` is run, a global `Nuiterm` lua table is exposed from which methods can be called, which is used in the mappings above.

### Telescope integration
The telescope picker to toggle terminals can be called via:
```lua
    require('nuiterm.telescope').picker
```
*It is not registered as a telescope extension*

## Configuration

The default plugin configuration is:
```lua
  Nuiterm.config = {
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
```

**Note:** By default terminals are opened in `splits` and are toggled often. It can thus helpful to set the vim option `:noequalalways` or `:lua vim.o.equalalways = false` to avoid constant resizing of windows.

## Task-specific terminals
A common use case for the floating/popup terminals provided with this plugin is to quickly open a TUI such as `lazygit`.
This can be easily accomplished with `nuiterm` via:

```lua
local function lazygit_terminal()
  local term = require("nuiterm").create_new_term({
    type = "editor",
    type_id = 100,
    keymaps = {{'t', '<esc>', '<esc>'}},
    ui = {
      type = "float",
      default_popup_opts = {border={text={top="Lazygit"}}}
    }
  })
  term:show(true,"lazygit")
end
vim.keymap.set('n','<leader>g',lazygit_terminal)
```

## Comparisons
There are almost infinite other terminal management plugins for neovim, yet I couldn't seem to find one that did what I needed.
Here are the closest:
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim):
   - This was the main inspiriation for this plugin and the design of using
     a `Terminal` object was based on the `toggleterm` design
   - The downside of this plugin is its inability to easily make terminals
     that are local to buffers, windows, or tabs for quickly sending text
     from specific buffers to specific terminals
- [nyngwang/NeoTerm.lua](https://github.com/nyngwang/NeoTerm.lua):
   - This plugin focuses on buffer specific terminals but with very few
     features
- [caenrique/nvim-toggle-terminal](https://github.com/caenrique/nvim-toggle-terminal):
   - Has great features and toggles tab specific and window specific
     terminals (but replaced by [caenrique/buffer-term.nvim](https://github.com/caenrique/buffer-term.nvim))

## Future possibilities

- [ ] Display multiple terminals simultaneously in `nui.layout`
- [ ] Implement distinction for REPL terminals with new display options
  - [ ] Separate display from output
    - [ ] Output only the REPL output not the input
      - [ ] Floating notification like output window in corner of screen (that can disappear after a given time)
    - [ ] Display results inline with `nui.text` and `nui.line`
  - [ ] If editing a remote file (either via scp or with fuse), option to open repl on remote machine
