--- *nuiterm* Neovim terminal manager for terminals local to buffer, window, tab, or editor
--- *Nuiterm*
---
--- MIT License Copyright (c) 2024 Connor Robertson
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
--- which contains the `terminals`.
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
---   vim.keymap.set('v', '<localleader>Rs', function() require('nuiterm').send_visual("select") end)
---   vim.keymap.set('v', '<localleader>Rc', function() require('nuiterm').send_visual("current") end)
---   vim.keymap.set('n', '<localleader>t', require('nuiterm').toggle_menu)
--- <
---
--- ## Usage as repl
--- A terminal connected to the current buffer can be easily made a REPL by
--- adjusting the keymap to send a REPL setup command on toggle (python for
--- example):
--- >
---   vim.keymap.set({'n','t'},'<c-n>',function() Nuiterm.toggle(nil,nil,"python") end)
--- <
---
--- ## Opening new global terminal
--- If a new, unused global terminal is desired, you can pass in -1 as the id
--- for an "editor" type terminal:
--- >
---   -- Open a new global terminal
---   vim.keymap.set('n', '<c-n>', function() Nuiterm.toggle("editor",-1) end)
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
---    local term = Nuiterm.terminals["editor"]["lazygit"] or Nuiterm.create_new_term({
---      type = "editor",
---      type_id = "lazygit", -- Can only use string `type_id` for "editor" terminals
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
--- # Available commands
---
--- ```vim
--- :Nuiterm [[type=]...] [[num=]...] [[cmd=]...]
--- :[count|range]NuitermSend [[cmd=]...] [[type=]...] [[num=]...] [[setup_cmd=]...]
--- :NuitermChangeStyle [[style=]...] [[type=]...] [[num=]...]
--- :NuitermChangeLayout [[type=]...] [[num=]...]
--- :NuitermBindBuf [[type=]...] [[num=]...]
--- :NuitermHideAll
--- :NuitermMenu
--- ```
---
--- **Note:** Commands can be used with or without keyword arguments. i.e. `Nuiterm type=editor` is the same as `Nuiterm editor`.
---
--- ### Examples
---
--- ```vim
--- " Toggle a terminal of default type and number
--- :Nuiterm
---
--- " Toggle a terminal for buffer 10
--- :Nuiterm type=buffer num=10
---
--- " Toggle a terminal for buffer 10 and start it with command `lua` if it doesn't already exist
--- :Nuiterm type=buffer num=10 cmd=lua
---
--- " Send the current line to the terminal of default type and number
--- :NuitermSend
---
--- " Send `lua` to the terminal associated with tab 2
--- :NuitermSend cmd=lua type=tab num=2
---
--- " Send the line 10 to the terminal associated with tab 2
--- :10NuitermSend type=tab num=2
---
--- " Send `lua` to the terminal of your choosing from terminal menu
--- :NuitermSend cmd=lua type=select
---
--- " Send `lua` to the terminal of your choosing from terminal menu
--- :NuitermSend cmd=lua num=select
---
--- " Send lines 10 to 20 to the terminal associated with tab 2
--- :10,20NuitermSend type=tab num=2
---
--- " Send visual selection to the terminal associated with tab 2
--- :'<,'>NuitermSend type=tab num=2
---
--- " Send print("hello") to the terminal associated with tab 2
--- " and if it hasn't been started before, send python first
--- :NuitermSend cmd=print("hello") type=tab num=2 setup_cmd=python
---
--- " Change to popup style for terminal associated with tab 2
--- :NuitermChangeStyle style=popup type=tab num=2
---
--- " Change layout to next layout in config for terminal associated with tab 2
--- " (see help docs for fine grained control in lua interface)
--- :NuitermChangeLayout type=tab num=2
---
--- " Bind the current buffer to send to the editor 3 terminal
--- :NuitermBindBuf type=editor num=3
--- ```
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

local Split = require("nui.split")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
local Terminal = require("nuiterm.terminal")
local utils = require("nuiterm.utils")
local menu = require("nuiterm.menu")
local user_commands = require("nuiterm.user_commands")
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
Nuiterm.windows = {}

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

  -- Add user commands
  user_commands.create_commands()

  -- Add autocommands
  Nuiterm.augroup = vim.api.nvim_create_augroup("Nuiterm", {clear = true})

  -- Only allow terminals in terminal windows
  if Nuiterm.config.terminal_win_fixed then
    vim.api.nvim_create_autocmd({"BufWinEnter"}, {
      group = "Nuiterm",
      pattern = {"*"},
      callback = function()
        local prev_file_nuiterm = vim.api.nvim_eval('bufname("#") =~ "nuiterm:"')
        local cur_file_nuiterm = vim.api.nvim_eval('bufname("%") =~ "nuiterm:"')
        local prev_bufwin = vim.api.nvim_eval('win_findbuf(bufnr("#"))')
        if (prev_file_nuiterm == 1) and (cur_file_nuiterm == 0) and (#prev_bufwin == 0) then
          vim.schedule(function()vim.cmd[[b#]]end)
        end
      end
    })
  end

  -- Clean up terminals on exit (helps session management)
  vim.api.nvim_create_autocmd({"ExitPre"}, {
    group = "Nuiterm",
    pattern="*",
    callback = function()
      local terms_mounted = utils.find_mounted()
      if terms_mounted then
        for _,term_info in ipairs(terms_mounted) do
          local term = Nuiterm.terminals[term_info[1]][term_info[2]]
          term:unmount()
        end
      end
    end
  })

  -- Automatically enter insert mode when entering terminal
  if Nuiterm.config.insert_on_enter == true then
    vim.api.nvim_create_autocmd({"BufEnter"}, {
      group = "Nuiterm",
      pattern="nuiterm:*",
      callback = function()
        vim.schedule(function() vim.cmd[[startinsert]] end)
        vim.cmd("redraw")
      end
    })
    vim.api.nvim_create_autocmd({"BufLeave"}, {
      group = "Nuiterm",
      pattern="nuiterm:*",
      callback = function()
        vim.schedule(function() vim.cmd[[stopinsert]] end)
        vim.cmd("redraw")
      end
    })
  end

  -- Abbreviations
  if Nuiterm.config.confirm_quit == true then
    vim.cmd[[cnoreabbrev <silent> <expr> q getcmdtype() == ":" && getcmdline() == 'q' ? 'lua Nuiterm.confirm_quit(false, false)' : 'q']]
    vim.cmd[[cnoreabbrev <silent> <expr> qa getcmdtype() == ":" && getcmdline() == 'qa' ? 'lua Nuiterm.confirm_quit(false, true)' : 'qa']]
    vim.cmd[[cnoreabbrev <silent> <expr> wq getcmdtype() == ":" && getcmdline() == 'wq' ? 'lua Nuiterm.confirm_quit(true, false)' : 'wq']]
    vim.cmd[[cnoreabbrev <silent> <expr> wqa getcmdtype() == ":" && getcmdline() == 'wqa' ? 'lua Nuiterm.confirm_quit(true, true)' : 'wqa']]
  end
end

--- Create terminal window
---
---@param opts table|nil Terminal UI config table
---
---@usage `Nuiterm.create_term_win({})` (replace `{}` with UI `config` table)
---
---@return |nui.object|
function Nuiterm.create_term_win(opts)
  opts = opts or {}
  local tpage = vim.api.nvim_get_current_tabpage()
  if opts.type == "split" then
    Nuiterm.windows[tpage] = Split(opts.options)
  else
    Nuiterm.windows[tpage] = Popup(opts.options)
  end
  Nuiterm.windows[tpage]:mount()
  vim.api.nvim_win_set_option(Nuiterm.windows[tpage].winid,"number",false)

  -- Save window info to each terminal
  Nuiterm.windows[tpage]:on({event.WinLeave}, function()
    local term = utils.find_by_bufnr(Nuiterm.windows[tpage].bufnr)
    if Nuiterm.config.persist_size then
      if Nuiterm.windows[tpage]._.size.width then
        local new_width = vim.api.nvim_win_get_width(Nuiterm.windows[tpage].winid)
        if term then
          term.ui.width = new_width
        end
      end
      if Nuiterm.windows[tpage]._.size.height then
        local new_height = vim.api.nvim_win_get_height(Nuiterm.windows[tpage].winid)
        if term then
          term.ui.height = new_height
        end
      end
    end
    if Nuiterm.config.hide_on_leave then
      Nuiterm.windows[tpage]:hide()
    end
  end, {})

  return Nuiterm.windows[tpage]
end

--- Show terminal window
---
---@param term Terminal Terminal to be displayed in window
function Nuiterm.show_term_win(term)
  local tpage = vim.api.nvim_get_current_tabpage()
  if (term.ui.type == "popup") or (term.ui.type == "float") then
    Nuiterm.hide_all_terms()
    Nuiterm.windows[tpage] = Popup(term.ui.options)
  else
    Nuiterm.hide_all_terms()
    Nuiterm.windows[tpage] = Split(term.ui.options)
  end
  Nuiterm.windows[tpage]:mount()
  vim.api.nvim_win_set_option(Nuiterm.windows[tpage].winid,"number",false)
  vim.api.nvim_win_set_buf(Nuiterm.windows[tpage].winid, term.bufnr)
  Nuiterm.windows[tpage].bufnr = term.bufnr
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
  -- for group,_ in pairs(Nuiterm.terminals) do
  --   for _,other_term in pairs(Nuiterm.terminals[group]) do
  --     if other_term:isshown() then
  --       other_term:hide(Nuiterm.config.persist_size)
  --     end
  --   end
  -- end
  local tpage = vim.api.nvim_get_current_tabpage()
  if Nuiterm.windows[tpage] then
    Nuiterm.windows[tpage]:hide()
  end
end

--- Toggle terminal
---
--- Note: if the cursor is in a terminal, that terminal will be hidden
---
---@param type string|nil the type of terminal to toggle (see |Nuiterm.config|)
---@param num integer|string|nil the id of the terminal to toggle
---@param cmd string|nil a command to run in terminal (if opening for the first time)
---
---@usage `Nuiterm.toggle('buffer', 12)` (toggle the terminal bound to buffer 12)
---@usage `Nuiterm.toggle('editor', 2)` (toggle the global terminal number 2)
---@usage `Nuiterm.toggle()` (toggle the default terminal for this buffer/window/tab/editor)
---@usage `Nuiterm.toggle('editor', 2, 'python')` (run python in global terminal 2 - if opening)
---@usage `Nuiterm.toggle('editor', -1)` (open a new global terminal)
function Nuiterm.toggle(type,num,cmd)
  local term,type,type_id = utils.find_by_type_and_num(type,num)

  if term and term:isshown() then
    Nuiterm.hide_all_terms()
  else
    Nuiterm.hide_all_terms()
    if term == nil then
      term = Nuiterm.create_new_term({type=type,type_id=type_id})
    end
    term:show(Nuiterm.config.focus_on_open,cmd)
  end
end

--- Change terminal UI style
---
---@param style string|nil the ui style to change to (or swap if nil)
---@param type string|nil the type of terminal to toggle (see |Nuiterm.config|)
---@param num integer|nil the id of the terminal to toggle
function Nuiterm.change_style(style,type,num)
  local term,_,_ = utils.find_by_type_and_num(type,num)

  if term ~= nil then
    if style == nil then
      if term.ui.type == "split" then
        style = "popup"
      else
        style = "split"
      end
      term.ui.num_layout = 1
    end
    term:change_style(style)
  end
end

--- Change terminal UI layout
---
---@param layout table|nil see nui.popup:update_layout
---@param type string|nil the type of terminal to toggle (see |Nuiterm.config|)
---@param num integer|nil the id of the terminal to toggle
function Nuiterm.change_layout(layout,type,num)
  local term,_,_ = utils.find_by_type_and_num(type,num)

  if term ~= nil then
    if layout == nil then
      local num_layout = term.ui.num_layout + 1
      local style = term.ui.type
      if num_layout > #Nuiterm.config.ui.default_layouts[style] then num_layout = 1 end
      layout = Nuiterm.config.ui.default_layouts[style][num_layout]
      term.ui.num_layout = num_layout
    end
    term:change_layout(layout)
  end
end

--- Rename terminal (only works for "editor" terminals)
---
---@param name string name for terminal (set as `type_id` in Terminal)
---@param type string|nil the type of terminal to rename (see |Nuiterm.config|)
---@param num integer|nil the id of the terminal to rename
function Nuiterm.rename_terminal(name,type,num)
  local term,_,_ = utils.find_by_type_and_num(type,num)
  type = type or term.type
  local type_id = num or term.type_id
  if type == "editor" then
    Nuiterm.terminals[type][name] = term
    Nuiterm.terminals[type][tostring(type_id)] = nil
    term.type_id = name
  else
    vim.print("Renaming only works for 'editor' type terminals")
  end
end

--- Delete terminal
---
---@param type string|nil the type of terminal to delete (see |Nuiterm.config|)
---@param type_id integer|string|nil the id of the terminal to delete
function Nuiterm.delete_terminal(type,type_id)
  if type and type_id then
    local term = Nuiterm.terminals[type][tostring(type_id)]
    if term then
      for k,v in pairs(term) do
        if k == "bufnr" and v ~= nil then
          vim.api.nvim_buf_delete(v, {force=true, unload=false})
        end
        term[k] = nil
      end
    end
  end

  -- Garbage collect (to deal with bound terminals)
  local types = {"editor", "buffer", "window", "tab"}
  for _,temp_type in ipairs(types) do
    for k,temp_term in pairs(Nuiterm.terminals[temp_type]) do
      if rawequal(next(temp_term), nil) then
        Nuiterm.terminals[temp_type][k] = nil
      end
    end
  end
end

--- Focus the buffer tied to the terminal under cursor in window 1
---
---@param bufnr number|nil the buffer number of the terminal
function Nuiterm.focus_buffer_for_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local _,group,id = utils.find_by_bufnr(bufnr)
  if group == "buffer" then
    local winid = vim.fn.win_getid(1)
    vim.api.nvim_win_set_buf(winid,id)
    vim.api.nvim_set_current_win(winid)
  end
end

--- Bind current buffer to terminal
---
---@param type string|nil the type of terminal to bind to (see |Nuiterm.config|)
---@param num integer|nil the id of the terminal to rename
function Nuiterm.bind_buf_to_terminal(type,num)
  if type == nil or num == nil then
    local on_submit = function(item) menu.bind_submit(item) end
    menu.show_menu(on_submit)
  else
    local term,_,_ = utils.find_by_type_and_num(type,num)
    type = type or term.type
    local current_buf = vim.api.nvim_get_current_buf()
    Nuiterm.delete_terminal("buffer", current_buf)
    Nuiterm.terminals["buffer"][tostring(current_buf)] = term
  end
end

--- Send text to a terminal
---
---@param cmd string the command to send to the terminal
---@param type string|nil the type of terminal to send to (or default). "select" to select from menu, "current" to use open terminal
---@param num number|string|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send(cmd,type,num,setup_cmd)
  local term,type,type_id = utils.find_by_type_and_num(type,num)

  -- Ensure term exists and is shown with setup_cmd
  local term_shown = utils.find_shown()
  Nuiterm.hide_all_terms()
  term = term or Nuiterm.create_new_term({type=type,type_id=type_id})
  term:show(Nuiterm.config.focus_on_send,setup_cmd)

  -- Send
  term:send(cmd..'\n')

  -- Put cursor at bottom of terminal buffer
  local tpage = vim.api.nvim_get_current_tabpage()
  vim.api.nvim_win_call(Nuiterm.windows[tpage].winid, function()
    local buf_len = vim.api.nvim_buf_line_count(Nuiterm.windows[tpage].bufnr)
    vim.api.nvim_win_set_cursor(Nuiterm.windows[tpage].winid, {buf_len,0})
  end)

  -- Hide terminal if it should be hidden
  if not Nuiterm.config.show_on_send then
    Nuiterm.hide_all_terms()
    if term_shown then
      local same_term = (term_shown[1] == term.type) and (term_shown[2] == term.type_id)
      local temp_term = Nuiterm.terminals[term_shown[1]][term_shown[2]]
      local focus = false
      if same_term then
        if Nuiterm.config.focus_on_send then
          focus = true
        end
      end
      temp_term:show(focus)
    end
  end
end


--- Wrap sending text to a terminal to allow for selecting terminal
---
---@param cmd string the command to send to the terminal
---@param type string|nil the type of terminal to send to (or default). "select" to select from menu, "current" to use open terminal
---@param num number|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_select(cmd,type,num,setup_cmd)
  if (type == "select") or (num == "select") then
    local on_submit = function(item) menu.send_submit(item, cmd, setup_cmd) end
    menu.show_menu(on_submit)
  else
    Nuiterm.send(cmd,type,num,setup_cmd)
  end
end

--- Send current line in buffer to a terminal
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_line(type,num,setup_cmd)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0,row-1,row,true)
  line = string.gsub(line[1], "^%s+", "")
  Nuiterm.send_select(line,type,num,setup_cmd)
end

--- Send multiple lines in buffer to a terminal
---
---@param start_line number|nil the line number at which to start sending
---@param end_line number|nil the line number at which to end sending
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_lines(start_line,end_line,type,num,setup_cmd)
  local lines = vim.api.nvim_buf_get_lines(0,start_line-1,end_line,false)
  local no_empty = {}
  local whitespace = 0
  for i, v in ipairs(lines) do
    if (string.gsub(v, "%s+", "") ~= "") then
      if i == 1 then
        local leading_whitespace = string.match(v, "^%s+")
        if leading_whitespace then
          whitespace = leading_whitespace:len()
        end
      end
      no_empty[#no_empty+1] = string.sub(v, whitespace+1)
    end
  end
  no_empty[#no_empty+1] = ""
  local combined = table.concat(no_empty,"\n")
  Nuiterm.send_select(combined,type,num,setup_cmd)
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
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_selection(line,start_col,end_col,type,num,setup_cmd)
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
  Nuiterm.send_select(table.concat(text),type,num,setup_cmd)
end

--- Send visual selection
---
--- Note: this is robust to reverse selections
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_visual(type,num,setup_cmd)
  local start_line, start_col = unpack(vim.fn.getpos("v"), 2, 4)
  local end_line, end_col = unpack(vim.fn.getpos("."), 2, 4)
  if (start_line == end_line) and (start_col ~= end_col) then
    Nuiterm.send_selection(start_line,start_col,end_col,type,num,setup_cmd)
  else
    if start_line > end_line then
      Nuiterm.send_lines(end_line,start_line,type,num,setup_cmd)
    else
      Nuiterm.send_lines(start_line,end_line,type,num,setup_cmd)
    end
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', false, true, true), 'nx', false)
end

--- Send file contents to terminal
---
---@param type string|nil the type of terminal to send to (or default)
---@param num number|nil the id of the terminal (type specific)
---@param setup_cmd string|nil the first command to send to a freshly opened terminal (if needed)
function Nuiterm.send_file(type,num,setup_cmd)
  local start_line = 1
  local end_line = vim.api.nvim_buf_line_count(0)
  Nuiterm.send_lines(start_line,end_line,type,num,setup_cmd)
end

--- Toggle terminal menu to select (and toggle) terminals
---
function Nuiterm.toggle_menu()
  if menu.menu_layout and menu.menu_layout.winid then
    menu.menu_layout:unmount()
  else
    menu.show_menu()
  end
end

--- Confirm quit commands when terminals are mounted
---
---@param write boolean|nil whether to write before quitting
---@param all boolean|nil if all windows are being quit
function Nuiterm.confirm_quit(write, all)
  local terms_mounted = utils.find_mounted()
  local num_windows = #vim.api.nvim_list_wins()

  if terms_mounted then
    if all == false and num_windows > 1 then
      -- Only closing one of multiple windows
      utils.write_quit(write, false)
    else
      -- Closing all windows or the only window
      vim.ui.input({prompt = "Active terminals. Exit? (y/n/[s]how) "}, function(input)
        if input == "y" then
          utils.write_quit(write, true)
        elseif input == "" or input == "s" or input == "show" then
          menu.show_menu()
        end
      end)
    end
  else
    utils.write_quit(write, all)
  end
end

return Nuiterm

