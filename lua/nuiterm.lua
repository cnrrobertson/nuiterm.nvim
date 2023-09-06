vim = vim
local Terminal = require("nuiterm.terminal")
local Menu = require("nui.menu")
local defaults = require("nuiterm.config").defaults
local utils = require("nuiterm.utils")
local menu = require("nuiterm.menu")
local nuiterm = {}

Nuiterms = {
  editor = {},
  tab = {},
  window = {},
  buffer = {}
}
nuiterm.menu_mounted = false
nuiterm.menu_shown = false

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
    local type_id = utils.get_type_id(type,num)
    term = Nuiterms[type][type_id] or nuiterm.create_new_term({type=type})
  end

  for group,_ in pairs(Nuiterms) do
    for _,other_term in pairs(Nuiterms[group]) do
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
  for group,_ in pairs(Nuiterms) do
    for _,term in pairs(Nuiterms[group]) do
      if term.bufnr == bufnr then
        return term
      end
    end
  end
end

function nuiterm.find_terminal_group_and_id(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for group,_ in pairs(Nuiterms) do
    for id,term in pairs(Nuiterms[group]) do
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
    local type_id = utils.get_type_id(type,num)
    term = Nuiterms[type][type_id] or nuiterm.create_new_term({type=type})
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

function nuiterm.show_terminal_menu()
  local lines = {}
  menu.add_editor_terms(lines)
  menu.add_tab_terms(lines)
  menu.add_window_terms(lines)
  menu.add_buffer_terms(lines)
  nuiterm.terminal_menu = Menu(menu.menu_options, {
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
        nuiterm.toggle(item.type,item.type_id)
      end
      nuiterm.menu_shown = false
    end,
    on_close = function()
      nuiterm.menu_shown = false
    end
  })
  nuiterm.terminal_menu:mount()
  nuiterm.menu_shown = true
end

-- Ensure terminal is left properly
vim.api.nvim_create_autocmd({"BufUnload"}, {
  pattern = {"nuiterm*"},
  callback = function(ev)
    local term_group,term_id = nuiterm.find_terminal_group_and_id(ev.buf)
    if Nuiterms then
      Nuiterms[term_group][term_id].ui.object:unmount()
      Nuiterms[term_group][term_id].ui.mounted = false
      Nuiterms[term_group][term_id].ui.shown = false
      Nuiterms[term_group][term_id].bufnr = nil
    end
  end
})

return nuiterm

