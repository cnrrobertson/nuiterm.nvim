--- *nuiterm* Neovim terminal manager for terminals local to buffer, window, tab, or editor
--- *Nuiterm*
---
--- MIT License Copyright (c) 2023 Connor Robertson
---
--- ===========================================================================
---
--- Key features:
--- - Quickly toggle window with terminal buffer inside
---
--- - Terminal buffer is local to buffer, window, tab, or editor in that it
---   can be quickly toggled and text can be sent to it from it's respective
---   locality
---
--- - Terminals can be quickly toggled from a menu or telescope extension
---
--- - Text can be easily sent from buffer to terminal (line, visual selection,
---   visual line selection, etc.) built with a REPL in mind
---
--- # Setup~
---
--- This plugin needs to be setup with `require('nuiterm').setup({})` (replace
--- `{}` with you `config` table). It will create a global Lua table `Nuiterm`
--- which contains the `terminals` and `data`.
---
--- See |Nuiterm.config| for available config settings.
---
--- ## Dependencies~
--- - 'MunifTanjim/nui.nvim' for UI
--- - (optional) 'nvim-telescope/telescope.nvim' for extra terminal finder
---
--- ## Example config with keybindings~
--- >
---   require('nuiterm').setup({
---     type = "buffer",
---     focus_on_open = false,
---     focus_on_send = false,
---   })
---   -- Toggle terminal of default type
---   vim.keymap.set({'n','t'},'<c-n>',Nuiterm.toggle)
---   -- (For buffer-type terminals) show connected buffer in window 1
---   vim.keymap.set({'n','t'},'<c-p>',Nuiterm.focus_buffer_for_terminal)
---   -- Toggle global terminal number 1
---   vim.keymap.set('n','<leader>n',function()Nuiterm.toggle("editor",1)end)
---
---   -- Toggle terminal menu
---   vim.keymap.set('n','<leader>tm',Nuiterm.toggle_menu)
---   vim.keymap.set('t','<c-t>',Nuiterm.toggle_menu)
---   vim.keymap.set('n','<leader>ft',require('nuiterm.telescope').picker)
---
---   -- Sending lines to terminal
---   vim.keymap.set('n', '<localleader>r', require('nuiterm').send_line)
---   vim.keymap.set('v', '<localleader>r', require('nuiterm').send_visual)
---   vim.keymap.set('n', '<localleader>t', require('nuiterm').toggle_menu)
--- <
---
--- ## Telescope integration~
--- `telescope.nvim` can be used to find and pick terminals to toggle via
--- keymap as:
--- >
---   vim.keymap.set('n','<leader>f',require('nuiterm.telescope').picker)
--- <
---
--- ## Task-specific terminals~
--- A common use case for floating terminals such as are provided with this
--- plugin is to quickly open a TUI such as `lazygit`. This can be easily
--- accomplished with nuiterm via:
---
--- >
---   local function lazygit_terminal()
---    local term = require("nuiterm").create_new_term({
---      type = "editor",
---      type_id = 100,
---       keymaps = {{'t', '<esc>', '<esc>'}},
---      ui = {
---        type = "float",
---        default_popup_opts = {border={text={top="Lazygit"}}}
---      }
---    })
---    term:show(true,"lazygit")
---   end
---   vim.keymap.set('n','<leader>g',lazygit_terminal)
--- <
---
--- # Tips~
---
--- - Given that most terminals are implemented as vim `splits` and are opened
---   and closed constantly, it is helpful to set the vim option `:noequalalways`
---   or `:lua vim.o.equalalways = false` to stop constant window resizing
---
--- # Comparisons~
---
--- - 'akinsho/toggleterm.nvim':
---    - This was the main inspiriation for this plugin and the design of using
---      a `Terminal` object was based on the `toggleterm` design
---    - The downside of this plugin is it's inability to easily make terminals
---      that are local to buffers, windows, or tabs for quickly sending text
---      from specific buffers to specific terminals
--- - 'nyngwang/NeoTerm.lua':
---    - This plugin focuses on buffer specific terminals but with very few
---      features
--- - 'caenrique/nvim-toggle-terminal':
---    - Has great features and toggles tab specific and window specific
---      terminals (but replaced by 'caenrique/buffer-term.nvim')
---
-- Plugin definition ==========================================================
local Nuiterm = {}

local Menu = require("nui.menu")
local Terminal = require("nuiterm.terminal")
local utils = require("nuiterm.utils")
local menu = require("nuiterm.menu")
Nuiterm.config = require("nuiterm.config")

--- Nuiterm data storage
---
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
Nuiterm.terminals = {
  editor = {},
  tab = {},
  window = {},
  buffer = {}
}
Nuiterm.data = {}
Nuiterm.menu_mounted = false
Nuiterm.menu_shown = false

--- Plugin setup
---
---@param config table|nil Plugin config table. See |Nuiterm.config|.
---
---@usage `require('nuiterm').setup({})` (replace `{}` with your `config` table)
function Nuiterm.setup(config)
  -- Export module
  _G.Nuiterm = Nuiterm

  -- Setup config
  Nuiterm.config = vim.tbl_deep_extend('force', Nuiterm.config, config or {})
end

--- Create new terminal
---
---@param opts table|nil Terminal config table. See |Nuiterm.config|
---
---@usage `Nuiterm.create_new_term({})` (replace `{}` with your `config` table)
---
---@return |Terminal|
function Nuiterm.create_new_term(opts)
  return Terminal:new(opts)
end

--- Hide all visible terminals
---
---@usage `Nuiterm.hide_all_terms()`
function Nuiterm.hide_all_terms()
  for group,_ in pairs(Nuiterm.terminals) do
    for _,other_term in pairs(Nuiterm.terminals[group]) do
      if other_term.ui.shown == true then
        other_term:hide()
      end
    end
  end
end

--- Toggle terminal
---
--- Note: if the cursor is in a terminal, that terminal will be hidden
---
---@param type string|nil the type of terminal to toggle (see |Nuiterm.config|)
---@param num int|nil the id of the terminal to toggle
---@param cmd string|nil a command to run in terminal (if opening for the first time)
---
---@usage `Nuiterm.toggle('buffer', 12)` (toggle the terminal bound to buffer 12)
---@usage `Nuiterm.toggle('editor', 2)` (toggle the global terminal number 2)
---@usage `Nuiterm.toggle()` (toggle the default terminal for this buffer/window/tab/editor)
---@usage `Nuiterm.toggle('editor', 2, 'python')` (run python in global terminal 2 - if opening)
function Nuiterm.toggle(type,num,cmd)
  type = type or Nuiterm.config.type
  local ft = vim.bo.filetype
  local term = {}
  if ft == "terminal" then
    term,_,_ = Nuiterm.find_terminal()
  else
    local type_id = utils.get_type_id(type,num)
    term = Nuiterm.terminals[type][type_id] or Nuiterm.create_new_term({type=type})
  end

  if term.ui.shown then
    term:hide()
  else
    Nuiterm.hide_all_terms()
    term:show(Nuiterm.config.focus_on_open,cmd)
  end
end

--- Retrieve Terminal object and info from terminal buffer number
---
---@param bufnr number|nil the buffer number of the desired terminal
---
---@return Terminal the Terminal object
---@return string the type of terminal it is
---@return number the id of the terminal (type specific)
function Nuiterm.find_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for group,_ in pairs(Nuiterm.terminals) do
    for id,term in pairs(Nuiterm.terminals[group]) do
      if term.bufnr == bufnr then
        return term,group,id
      end
    end
  end
end

--- Focus the buffer tied to the terminal under cursor in window 1
---
---@param bufnr number|nil the buffer number of the terminal
function Nuiterm.focus_buffer_for_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local _,group,id = Nuiterm.find_terminal(bufnr)
  if group == "buffer" then
    local winid = vim.fn.win_getid(1)
    vim.api.nvim_win_set_buf(winid,id)
    vim.api.nvim_set_current_win(winid)
  end
end

--- Send text to a terminal
---
---@param cmd string the command to send to the terminal
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send(cmd,type,num)
  type = type or Nuiterm.config.type
  local ft = vim.bo.filetype
  local term = {}
  if ft == "terminal" then
    term,_,_ = Nuiterm.find_terminal()
  else
    local type_id = utils.get_type_id(type,num)
    term = Nuiterm.terminals[type][type_id] or Nuiterm.create_new_term({type=type})
  end
  Nuiterm.hide_all_terms()
  term:show(Nuiterm.config.focus_on_send)
  term:send(cmd..'\n')
  if not Nuiterm.config.show_on_send then
    term:hide()
    -- Strange bug: deal with entering insert mode if terminal is hidden
    -- vim.api.nvim_input[[<c-c>]]
  end
end

--- Send current line in buffer to a terminal
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send_line(type,num)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0,row-1,row,true)
  Nuiterm.send(line[1],type,num)
end

--- Send multiple lines in buffer to a terminal
---
---@param start_line string|nil the line number at which to start sending
---@param end_line string|nil the line number at which to end sending
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send_lines(start_line,end_line,type,num)
  local lines = vim.api.nvim_buf_get_lines(0,start_line-1,end_line,false)
  local no_empty = {}
  for _, v in ipairs(lines) do
    if (string.gsub(v, "%s+", "") ~= "") then
      no_empty[#no_empty+1] = v
    end
  end
  no_empty[#no_empty+1] = ""
  local combined = table.concat(no_empty,"\n")
  Nuiterm.send(combined,type,num)
end

--- Send selection in line in buffer to a terminal
---
--- Note: this is robust to reverse selections
---
---@param line string|nil the line number at which to send
---@param start_col string|nil the column number at which to start sending
---@param end_col string|nil the column number at which to end sending
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send_selection(line,start_col,end_col,type,num)
  local sc = nil
  local ec = nil
  if start_col > end_col then
    sc = end_col
    ec = start_col
  else
    sc = start_col
    ec = end_col
  end
  local text = vim.api.nvim_buf_get_text(0,line-1,sc-1,line-1,ec,{})
  Nuiterm.send(table.concat(text),type,num)
end

--- Send visual selection
---
--- Note: this is robust to reverse selections
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send_visual(type,num)
  local start_line, start_col = unpack(vim.fn.getpos("v"), 2, 4)
  local end_line, end_col = unpack(vim.fn.getpos("."), 2, 4)
  if (start_line == end_line) and (start_col ~= end_col) then
    Nuiterm.send_selection(start_line,start_col,end_col,type,num)
  else
    if start_line > end_line then
      Nuiterm.send_lines(end_line,start_line,type,num)
    else
      Nuiterm.send_lines(start_line,end_line,type,num)
    end
  end
end

--- Send file contents to terminal
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
function Nuiterm.send_file(type,num)
  local start_line = 1
  local end_line = vim.api.nvim_buf_line_count(0)
  Nuiterm.send_lines(start_line,end_line,type,num)
end

--- Toggle terminal menu to select (and toggle) terminals
---
function Nuiterm.toggle_menu()
  if Nuiterm.menu_shown then
    Nuiterm.terminal_menu:unmount()
    Nuiterm.menu_shown = false
  else
    Nuiterm.show_terminal_menu()
  end
end

--- Show terminal menu to select (and toggle) terminals
---
function Nuiterm.show_terminal_menu()
  local lines = {}
  menu.add_editor_terms(lines)
  menu.add_tab_terms(lines)
  menu.add_window_terms(lines)
  menu.add_buffer_terms(lines)
  Nuiterm.terminal_menu = Menu(Nuiterm.config.menu_opts, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
    on_submit = function(item)
      if item then
        Nuiterm.toggle(item.type,item.type_id)
      end
      Nuiterm.menu_shown = false
    end,
    on_close = function()
      Nuiterm.menu_shown = false
    end
  })
  Nuiterm.terminal_menu:mount()
  Nuiterm.menu_shown = true
end

-- Ensure terminal is left properly
vim.api.nvim_create_autocmd({"BufUnload"}, {
  pattern = {"Nuiterm:*"},
  callback = function(ev)
    local _,term_group,term_id = Nuiterm.find_terminal(ev.buf)
    if Nuiterm.terminals then
      Nuiterm.terminals[term_group][term_id].ui.object:unmount()
      Nuiterm.terminals[term_group][term_id].ui.mounted = false
      Nuiterm.terminals[term_group][term_id].ui.shown = false
      Nuiterm.terminals[term_group][term_id].bufnr = nil
    end
  end
})

-- Only allow terminals in terminal windows
if Nuiterm.config.terminal_win_fixed then
  vim.api.nvim_create_autocmd({"BufLeave"}, {
    pattern = {"Nuiterm:*"},
    callback = function(ev)
      Nuiterm.data['term_win_id'] = vim.api.nvim_get_current_win()
      Nuiterm.data['last_term_bufnr'] = ev.buf
    end
  })
  vim.api.nvim_create_autocmd({"BufEnter"}, {
    pattern = {"*"},
    callback = function(ev)
      if vim.api.nvim_get_current_win() == Nuiterm.data['term_win_id'] then
        if string.match(ev.file, "Nuiterm:") == nil then
          vim.api.nvim_win_set_buf(Nuiterm.data['term_win_id'], Nuiterm.data['last_term_bufnr'])
        end
      end
    end
  })
end

return Nuiterm

