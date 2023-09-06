vim = vim
local Menu = require("nui.menu")
local Split = require("nui.split")
local Popup = require("nui.Popup")
local nuiterm = {}

local defaults = {
  type = "buffer", -- or "editor" or "tab" or "window"
  show_on_send = true,
  focus_on_open = true,
  focus_on_send = false,
  ui = {
    type = "split",
    default_split_opts = {
      enter = true,
      focusable = true,
      border = {
        style = "rounded",
      },
      position = "right",
      size = "40%",
      relative = "editor",
    },
    default_popup_opts = {
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
    }
  }
}

nuiterm.terminals = {
  editor = {},
  tab = {},
  window = {},
  buffer = {}
}
function nuiterm.table_length(t)
  local length = 0
  for _,_ in pairs(t) do
    length = length + 1
  end
  return length
end
nuiterm.menu_mounted = false
nuiterm.menu_shown = false
local menu_options = {
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

function nuiterm.show_terminal_menu()
  local lines = {}
  if nuiterm.table_length(nuiterm.terminals["editor"]) > 0 then
    lines[#lines+1] = Menu.separator("Editor")
    for _,t in pairs(nuiterm.terminals["editor"]) do
      local menu_item = Menu.item(
        tostring(t.type_id),{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if nuiterm.table_length(nuiterm.terminals["tab"]) > 0 then
    lines[#lines+1] = Menu.separator("Tab")
    for _,t in pairs(nuiterm.terminals["tab"]) do
      local buf_names = ""
      for _,win in pairs(vim.api.nvim_tabpage_list_wins(t.type_id)) do
        buf_names = buf_names.." "..vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      end
      local display = "Tab: "..t.type_id.." -- Buffers in tab: "..buf_names
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if nuiterm.table_length(nuiterm.terminals["window"]) > 0 then
    lines[#lines+1] = Menu.separator("Window")
    for _,t in pairs(nuiterm.terminals["window"]) do
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(t.type_id))
      local display = "Window: "..t.type_id.." -- Buffer in window: "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if nuiterm.table_length(nuiterm.terminals["buffer"]) > 0 then
    lines[#lines+1] = Menu.separator("Buffer")
    for _,t in pairs(nuiterm.terminals["buffer"]) do
      local buf_name = vim.api.nvim_buf_get_name(t.type_id)
      local display = "Buffer: "..t.type_id.." -- Name: "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  nuiterm.terminal_menu = Menu(menu_options, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
    on_submit = function(item)
      nuiterm.toggle(item.type,item.type_id)
    end,
  })
  nuiterm.terminal_menu:mount()
  nuiterm.menu_shown = true
end

local Terminal = {}
function Terminal:new(options)
  options = options or {}
  options = vim.tbl_deep_extend("force",defaults,options)
  self.__index = self
  options.type = options.type
  options.type_id = nuiterm.get_type_id(options.type)
  options.bufnr = vim.api.nvim_create_buf(false,false)
  options.bufname = "nuiterm:" .. options.type .. ":" .. tostring(options.type_id)
  local ui_object = {}
  if options.ui.type == "split" then
    local bn = {bufnr = options.bufnr}
    local split_opts = vim.tbl_deep_extend("force",options.ui.default_split_opts,bn)
    ui_object = Split(split_opts)
  else
    local bn = {bufnr = options.bufnr}
    local popup_opts = vim.tbl_deep_extend("force",options.ui.default_popup_opts,bn)
    ui_object = Popup(popup_opts)
  end
  options.ui = {
    type = options.ui.type,
    mounted = false,
    shown = false,
    object = ui_object
  }
  local term = setmetatable(options,self)
  nuiterm.terminals[options.type][options.type_id] = term
  return term
end

function Terminal:show(focus,cmd)
  local start_win = vim.api.nvim_get_current_win()
  local start_cursor = vim.api.nvim_win_get_cursor(start_win)
  if self.ui.mounted == false then
    self.ui.object:mount()
    self.ui.mounted = true
    self.ui.shown = true
    if self.bufnr == nil then
      self.bufnr = vim.api.nvim_create_buf(false,false)
    end
    vim.api.nvim_win_set_buf(0,self.bufnr)
    if cmd then
      self.chan = vim.fn.termopen(cmd, {on_exit=function()vim.api.nvim_feedkeys("i","n","t")end})
    else
      self.chan = vim.fn.termopen(vim.o.shell, {on_exit=function()vim.api.nvim_feedkeys("i","n","t")end})
    end
    vim.api.nvim_buf_set_option(self.bufnr,"filetype","terminal")
    vim.api.nvim_win_set_option(0,"number",false)
    vim.api.nvim_buf_set_name(self.bufnr,self.bufname)
    if focus then
      -- Ensure insert mode on mount
      vim.api.nvim_feedkeys("i",'t',false)
    end
  elseif self.ui.shown == false then
    self.ui.object:show()
    vim.api.nvim_win_set_buf(0,self.bufnr)
    self.ui.shown = true
  end
  if not focus then
    vim.api.nvim_set_current_win(start_win)
    vim.api.nvim_win_set_cursor(start_win,start_cursor)
  end
end

function Terminal:hide()
  self.ui.object:hide()
  self.ui.shown = false
end

function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

function nuiterm.get_type_id(type,num)
  if num then
    return num
  else
    local type_id = 1
    if type == "editor" then
      type_id = num or nuiterm.table_length(nuiterm.terminals[type])+1
    elseif type == "tab" then
      type_id = vim.api.nvim_get_current_tabpage()
    elseif type == "window" then
      type_id = vim.api.nvim_get_current_win()
    elseif type == "buffer" then
      type_id = vim.api.nvim_get_current_buf()
    end
    return type_id
  end
end

function nuiterm.create_new_term(opts)
  return Terminal:new(opts)
end

function nuiterm.toggle(type,num)
  type = type or defaults.type
  local ft = vim.bo.filetype
  local term = {}
  if ft == "terminal" then
    term = nuiterm.find_terminal()
  else
    local type_id = nuiterm.get_type_id(type,num)
    term = nuiterm.terminals[type][type_id] or nuiterm.create_new_term({type=type})
  end

  for group,_ in pairs(nuiterm.terminals) do
    for _,other_term in pairs(nuiterm.terminals[group]) do
      if other_term.ui.shown == true then
        if other_term.bufnr ~= term.bufnr then
          other_term:hide()
        end
      end
    end
  end
  if term.ui.shown then
    term:hide()
  else
    term:show(defaults.focus_on_open)
  end
end

function nuiterm.find_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for group,_ in pairs(nuiterm.terminals) do
    for _,term in pairs(nuiterm.terminals[group]) do
      if term.bufnr == bufnr then
        return term
      end
    end
  end
end

function nuiterm.find_terminal_group_and_id(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for group,_ in pairs(nuiterm.terminals) do
    for id,term in pairs(nuiterm.terminals[group]) do
      if term.bufnr == bufnr then
        return group,id
      end
    end
  end
end

function nuiterm.send(cmd,type,num)
  type = type or defaults.type
  local ft = vim.bo.filetype
  local term = {}
  if ft == "terminal" then
    term = nuiterm.find_terminal()
  else
    local type_id = nuiterm.get_type_id(type,num)
    term = nuiterm.terminals[type][type_id] or nuiterm.create_new_term({type=type})
  end
  term:show(defaults.focus_on_send)
  term:send(cmd)
  if not defaults.show_on_send then
    term:hide()
    -- Strange bug: deal with entering insert mode if terminal is hidden
    -- vim.api.nvim_input[[<c-c>]]
  end
end

function nuiterm.send_line(type,num)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0,row-1,row,true)
  nuiterm.send(line[1]..'\n',type,num)
end

function nuiterm.send_lines(start_line,end_line,type,num)
  local lines = vim.api.nvim_buf_get_lines(0,start_line-1,end_line,false)
  local no_empty = {}
  for _, v in ipairs(lines) do
    if (string.gsub(v, "%s+", "") ~= "") then
      no_empty[#no_empty+1] = v
    end
  end
  no_empty[#no_empty+1] = ""
  local combined = table.concat(no_empty,"\n")
  nuiterm.send(combined,type,num)
end

function nuiterm.send_selection(line,start_col,end_col,type,num)
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
  nuiterm.send(table.concat(text),type,num)
end

function nuiterm.send_visual(type,num)
  local start_line, start_col = unpack(vim.fn.getpos("v"), 2, 4)
  local end_line, end_col = unpack(vim.fn.getpos("."), 2, 4)
  if (start_line == end_line) and (start_col ~= end_col) then
    nuiterm.send_selection(start_line,start_col,end_col,type,num)
  else
    nuiterm.send_lines(start_line,end_line,type,num)
  end
end

function nuiterm.send_file()
  local bufnum = vim.fn.bufnr()
  local top_row = 1
  local bot_row = vim.api.nvim_buf_line_count(0)
  nuiterm.send_lines(bufnum, top_row, bot_row)
end

function nuiterm.toggle_menu()
  if nuiterm.menu_shown then
    nuiterm.terminal_menu:unmount()
    nuiterm.menu_shown = false
  else
    nuiterm.show_terminal_menu()
  end
end

-- Ensure terminal is left properly
vim.api.nvim_create_autocmd({"BufUnload"}, {
  pattern = {"nuiterm*"},
  callback = function(ev)
    local term_group,term_id = nuiterm.find_terminal_group_and_id(ev.buf)
    if nuiterm.terminals then
      nuiterm.terminals[term_group][term_id].ui.object:unmount()
      nuiterm.terminals[term_group][term_id].ui.mounted = false
      nuiterm.terminals[term_group][term_id].ui.shown = false
      nuiterm.terminals[term_group][term_id].bufnr = nil
    end
  end
})

return nuiterm

