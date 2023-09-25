# nuiterm.nvim


Nuiterm provides an easy way to toggle and send code to terminals which are local to your buffer, window, tab, or editor.

It was designed with the idea that each buffer could have its own REPL running in a terminal buffer and that these terminal buffers would be easily toggled via keybinding or menu selection.
This was originally to replace the experience of Jupyter Interactive windows in VSCode in that I could run chunks of different files in different IPython REPLs.
The terminal UI is all done with [nui.nvim](https://github.com/MunifTanjim/nui.nvim) to allow for ease of use and future expansion.

Some features of the nuiterm:
    - Toggle a split/floating terminal for multiple buffers/windows/tabs
    - Toggle any number of global/editor based terminals
    - Send commands, lines from the buffer, or visual selections to any terminal
    - Quickly select a terminal to toggle from a built-in menu (or with telescope - see [Telescope integration](#telescope-integration))
    - Easily create and toggle task-specific terminals (such as for [lazygit](https://github.com/jesseduffield/lazygit) or [btop](https://github.com/aristocratos/btop))

Some oddities about the nuiterm (that may change in the future):
    - Option to not allow other buffers to hijack the terminal window
    - Can only display one terminal at a time

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
    -- Toggle global terminal number 1
    vim.keymap.set('n','<leader>n',function()Nuiterm.toggle("editor",1)end)

    -- Toggle terminal menu
    vim.keymap.set('n','<leader>tm',Nuiterm.toggle_menu)
    vim.keymap.set('t','<c-t>',Nuiterm.toggle_menu)
    vim.keymap.set('n','<leader>ft',require('nuiterm.telescope').picker)
  end,
}
```
After `setup` is run, a global `Nuiterm` lua table is exposed from which methods can be called.
Hence the keymappings above.

### Telescope integration
The telescope picker to toggle terminals can be called via:
```lua
    require('nuiterm.telescope').picker
```
It does not need to be registered as a telescope extension.

## Configuration

The default plugin configuration is:
```lua
  Nuiterm.config = {
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
```

**Note:** Because default terminals are opened in `splits` and are toggled often, it can be helpful to set the vim option `:noequalalways` or `:lua vim.o.equalalways = false`.

## Task-specific terminals
A common use case for floating terminals such as are provided with this plugin is to quickly open a TUI such as `lazygit`.
This can be easily accomplished with nuiterm via:

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
- [akinsho/toggleterm.nvim]:
   - This was the main inspiriation for this plugin and the design of using
     a `Terminal` object was based on the `toggleterm` design
   - The downside of this plugin is its inability to easily make terminals
     that are local to buffers, windows, or tabs for quickly sending text
     from specific buffers to specific terminals
- [nyngwang/NeoTerm.lua]:
   - This plugin focuses on buffer specific terminals but with very few
     features
- [caenrique/nvim-toggle-terminal]:
   - Has great features and toggles tab specific and window specific
     terminals (but replaced by [caenrique/buffer-term.nvim])

## Future possibilities
Given that this terminal plugin was developed with buffer-specific REPLs in mind, these focus on that idea:
- [ ] Implement special REPL terminal class with new display options
  - [ ] Separate display from output
    - [ ] Output only the output not the input
    - [ ] Display results inline with `nui.text` and `nui.line`
- [ ] Display multiple terminals simultaneously in `nui.layout`
