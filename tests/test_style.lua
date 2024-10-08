local child = MiniTest.new_child_neovim()
local equals = MiniTest.expect.equality
local nequals = MiniTest.expect.no_equality
local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({'--headless', '--noplugin', '-u', 'scripts/minimal_init.lua'})
      child.lua([[nuiterm = require('mini.test')]])
    end
  },
})

local init_plug = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")
end

local init_term = function()
  init_plug()
  child.cmd("Nuiterm")
end

local is_floating = function()
  nequals(child.api.nvim_win_get_config(0).relative, "")
end

local is_split = function()
  equals(child.api.nvim_win_get_config(0).relative, "")
end

local is_vertical = function()
  local win_height = child.api.nvim_win_get_height(0)
  local cmd_height = child.api.nvim_get_option_value("cmdheight",{})
  local nvim_height = child.api.nvim_get_option_value("lines",{})
  equals(win_height + cmd_height + 1, nvim_height)
end

local is_horizontal = function()
  local win_width = child.api.nvim_win_get_width(0)
  local nvim_width = child.api.nvim_get_option_value("columns",{})
  equals(win_width, nvim_width)
end

local has_height = function(height)
  local win_height = child.api.nvim_win_get_height(0)
  equals(win_height, height)
end

local has_width = function(width)
  local win_width = child.api.nvim_win_get_width(0)
  equals(win_width, width)
end

T["change_styles"] = function()
  init_term()

  is_split()
  child.cmd("NuitermChangeStyle")
  is_floating()
  child.lua("require('nuiterm').change_style()")
  is_split()

  -- Prescribe split
  child.lua("require('nuiterm').change_style('split')")
  is_split()

  -- Prescribe popup
  child.lua("require('nuiterm').change_style('popup')")
  is_floating()

  -- Prescribe split
  child.cmd("NuitermChangeStyle split")
  is_split()
end

-- TODO: Test adjusting layouts
T["change_split_layouts"] = function()
  init_term()

  is_vertical()
  child.cmd("NuitermChangeLayout")
  is_horizontal()
  child.lua("require('nuiterm').change_layout()")
  is_vertical()
  child.lua("require('nuiterm').change_layout({relative='editor', size='20%', position='left'})")
  is_vertical()
  child.lua("require('nuiterm').change_layout({relative='editor', size='20%', position='top'})")
  is_horizontal()
end

T["change_float_layouts"] = function()
  init_term()
  child.cmd("NuitermChangeStyle")

  -- Cycle
  has_height(19)
  has_width(64)
  child.cmd("NuitermChangeLayout")
  has_height(21)
  has_width(32)
  child.lua("require('nuiterm').change_layout()")
  has_height(9)
  has_width(32)
  child.cmd("NuitermChangeLayout")
  has_height(19)
  has_width(64)

  -- Prescribe
  child.lua("require('nuiterm').change_layout({relative='editor', size={height=12,width=24}, position='50%'})")
  has_height(12)
  has_width(24)
end

T["rename"] = function()
  init_plug()

  -- Open editor terminal
  child.cmd("Nuiterm type=editor")

  -- Ensure it exists
  local term_exists = child.lua_get("Nuiterm.terminals.editor['1']") ~= vim.NIL
  equals(term_exists, true)

  -- Rename terminal
  child.lua("Nuiterm.rename_terminal('check', 'editor', 1)")

  -- Ensure old doesn't exist and new does
  term_exists = child.lua_get("Nuiterm.terminals.editor['1']") ~= vim.NIL
  equals(term_exists, false)
  term_exists = child.lua_get("Nuiterm.terminals.editor['check']") ~= vim.NIL
  equals(term_exists, true)
end

T["rename_w_bind"] = function()
  init_plug()

  -- Open/hide editor terminal
  child.cmd("Nuiterm type=editor")
  child.cmd("Nuiterm")

  -- Bind buffer
  local file_buf = child.lua_get("vim.api.nvim_get_current_buf()")
  child.lua("Nuiterm.bind_buf_to_terminal('editor', 1)")

  -- Rename terminal
  child.lua("Nuiterm.rename_terminal('check', 'editor', 1)")

  -- Ensure old doesn't exist and new does
  local term_exists = child.lua_get("Nuiterm.terminals.editor['1']") ~= vim.NIL
  equals(term_exists, false)
  term_exists = child.lua_get("Nuiterm.terminals.editor['check']") ~= vim.NIL
  equals(term_exists, true)

  -- Ensure renaming worked for bound terminal
  term_exists = child.lua_get("Nuiterm.terminals.buffer['"..file_buf.."']") ~= vim.NIL
  equals(term_exists, true)
end

child.stop()
return T
