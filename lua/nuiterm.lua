--- *nuiterm* Neovim terminal manager for terminals "bound" to editor, tab, window, or buffer
--- *Nuiterm*

vim = vim
local Terminal = require("nuiterm.terminal")
local Menu = require("nui.menu")
local utils = require("nuiterm.utils")
local menu = require("nuiterm.menu")
Nuiterm = {}
Nuiterm.config = require("nuiterm.config")

Nuiterm.terminals = {
  editor = {},
  tab = {},
  window = {},
  buffer = {}
}
Nuiterm.data = {}
Nuiterm.menu_mounted = false
Nuiterm.menu_shown = false

function Nuiterm.create_new_term(opts)
  return Terminal:new(opts)
end

function Nuiterm.hide_all_terms()
  for group,_ in pairs(Nuiterm.terminals) do
    for _,other_term in pairs(Nuiterm.terminals[group]) do
      if other_term.ui.shown == true then
        other_term:hide()
      end
    end
  end
end

function Nuiterm.toggle(type,num)
  type = type or defaults.type
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
    term:show(defaults.focus_on_open)
  end
end

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

function Nuiterm.focus_buffer_for_terminal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local _,group,id = Nuiterm.find_terminal(bufnr)
  if group == "buffer" then
    local winid = vim.fn.win_getid(1)
    vim.api.nvim_win_set_buf(winid,id)
    vim.api.nvim_set_current_win(winid)
  end
end

function Nuiterm.send(cmd,type,num)
  type = type or defaults.type
  local ft = vim.bo.filetype
  local term = {}
  if ft == "terminal" then
    term,_,_ = Nuiterm.find_terminal()
  else
    local type_id = utils.get_type_id(type,num)
    term = Nuiterm.terminals[type][type_id] or Nuiterm.create_new_term({type=type})
  end
  Nuiterm.hide_all_terms()
  term:show(defaults.focus_on_send)
  term:send(cmd..'\n')
  if not defaults.show_on_send then
    term:hide()
    -- Strange bug: deal with entering insert mode if terminal is hidden
    -- vim.api.nvim_input[[<c-c>]]
  end
end

function Nuiterm.send_line(type,num)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0,row-1,row,true)
  Nuiterm.send(line[1],type,num)
end

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

function Nuiterm.send_file(type,num)
  local start_line = 1
  local end_line = vim.api.nvim_buf_line_count(0)
  Nuiterm.send_lines(start_line,end_line,type,num)
end

function Nuiterm.toggle_menu()
  if Nuiterm.menu_shown then
    Nuiterm.terminal_menu:unmount()
    Nuiterm.menu_shown = false
  else
    Nuiterm.show_terminal_menu()
  end
end

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
if defaults.terminal_win_fixed then
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

