# nuiterm.nvim

A Neovim plugin to toggle and send code to terminals which are local to your buffer, window, tab, or editor.

The key design motivation in this plugin was to facilitate a terminal/REPL for individual file buffers rather than having a single terminal/REPL for all buffers or each filetype.
With this, it mimics the REPL experience of using [Jupyter Interactive windows](https://code.visualstudio.com/docs/python/jupyter-support-py) in VSCode.
The UI is all done with [nui.nvim](https://github.com/MunifTanjim/nui.nvim) to allow for ease of use and expansion.

Some core features of `nuiterm`:

- Toggle a split/floating terminal for each buffer/window/tab
- Toggle any number of global/editor split/floating terminals
- Send commands, lines from the buffer, or visual selections to any terminal
- Quickly create/toggle/delete/adjust terminals from a popup menu (or with [telescope](https://github.com/nvim-telescope/telescope.nvim) - see [Telescope integration](#telescope-integration))
- Easily create and toggle task-specific terminals (such as for [lazygit](https://github.com/jesseduffield/lazygit) or [btop](https://github.com/aristocratos/btop))

Some oddities about `nuiterm` (that may change in the future):

- Can only display one terminal at a time
- Displaying the same terminal in multiple tabpages is not supported

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

    ---------------------
    -- EXAMPLE KEYMAPS --
    ---------------------
    -- Toggle terminal of default type
    vim.keymap.set({'n','t'},'<c-n>',Nuiterm.toggle)
    -- to always make it a Python REPL:
    -- vim.keymap.set({'n','t'},'<c-n>',function()Nuiterm.toggle(nil,nil,"python")end)

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
    require('nuiterm.telescope').picker()
```
**Note:** It is not registered as a telescope extension

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
  -- Number of parent directories to show for buffers in terminal menu
  menu_buf_depth = 1,
  -- Confirm destruction of terminals
  menu_confirm_destroy = true,
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
```

**Note:** By default terminals are opened in `splits` and are toggled often, so it can be helpful to set the vim option `:noequalalways` or `:lua vim.o.equalalways = false` to avoid constant window resizing.

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

## Available commands

```vim
:Nuiterm [[type=]...] [[num=]...] [[cmd=]...]
:[count|range]NuitermSend [[cmd=]...] [[type=]...] [[num=]...] [[setup_cmd=]...]
:NuitermChangeStyle [[style=]...] [[type=]...] [[num=]...]
:NuitermChangeLayout [[type=]...] [[num=]...]
:NuitermHideAll
:NuitermMenu
```

**Note:** Commands can be used with or without keyword arguments. i.e. `Nuiterm type=editor` is the same as `Nuiterm editor`.

### Examples

```vim
" Toggle a terminal of default type and number
:Nuiterm

" Toggle a terminal for buffer 10
:Nuiterm type=buffer num=10

" Toggle a terminal for buffer 10 and start it with command `lua` if it doesn't already exist
:Nuiterm type=buffer num=10 cmd=lua

" Send the current line to the terminal of default type and number
:NuitermSend

" Send `lua` to the terminal associated with tab 2
:NuitermSend cmd=lua type=tab num=2

" Send the line 10 to the terminal associated with tab 2
:10NuitermSend type=tab num=2

" Send lines 10 to 20 to the terminal associated with tab 2
:10,20NuitermSend type=tab num=2

" Send visual selection to the terminal associated with tab 2
:'<,'>NuitermSend type=tab num=2

" Send print("hello") to the terminal associated with tab 2
" and if it hasn't been started before, send python first
:NuitermSend cmd=print("hello") type=tab num=2 setup_cmd=python

" Change to popup style for terminal associated with tab 2
:NuitermChangeStyle style=popup type=tab num=2

" Change layout to next layout in config for terminal associated with tab 2
" (see help docs for fine grained control in lua interface)
:NuitermChangeLayout type=tab num=2
```

## Comparisons
There are almost infinite other terminal management plugins for neovim, yet I couldn't seem to find one that did what I needed.
Here are the closest:
- [akinsho/toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim):
   - This was the main inspiration for this plugin and the design of using
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
- [milanglacier/yarepl.nvim](https://github.com/milanglacier/yarepl.nvim#replstart)
    - Allows for general numbers of REPLs that can be attached to any buffer

## Contributing

Ideas/issues/pull requests are welcome.

If you would like to submit a pull request, please ensure you update the documentation and tests accordingly.
The plugins `mini.doc` and `mini.test` are used for documentation and testing respectively.
Docs can be generated with `make docs` from the root of the repository and `make test` to run the tests.

When running the documentation or tests, [`mini.nvim`](https://github.com/echasnovski/mini.nvim) and [`nui.nvim`](https://github.com/MunifTanjim/nui.nvim) will be installed in a `deps/` directory.

## Future possibilities

- [ ] Display multiple terminals simultaneously in `nui.layout`
- [ ] Implement distinction for terminals running a REPL with new display options
  - [ ] Separate display from output
    - [ ] Output only the REPL output not the input
    - [ ] Display results inline with `nui.text` and `nui.line`
  - [ ] If editing a remote file (either via scp or with fuse), option to open repl on remote machine
- [ ] Display additional terminal info in terminal menu
- [ ] Add ability to open buffer connected to terminal in a specific window (maybe number, or left, right, top, bottom, etc?)
- [ ] Add ability to "pin" terminal (don't close when toggling others)
