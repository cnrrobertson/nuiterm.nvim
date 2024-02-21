local child = MiniTest.new_child_neovim()
local equals = MiniTest.expect.equality
local nequals = MiniTest.expect.no_equality
local utils = require("tests.utils")
local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({'--headless', '--noplugin', '-u', 'scripts/minimal_init.lua'})
      child.lua([[nuiterm = require('mini.test')]])
    end
  },
})

local init_term = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")
end

T["bind"] = function()
  init_term()

  -- Get bufnr of file
  local fbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Create terminal
  child.cmd("Nuiterm type=editor num=1")

  -- Get bufnr of terminal
  local term_exists = child.lua_get("Nuiterm.terminals.editor['1']") ~= vim.NIL
  equals(term_exists, true)

  -- Hide and bind file
  child.cmd("Nuiterm")
  child.lua("Nuiterm.bind_buf_to_terminal('editor', 1)")
  local bterm = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']")
  local eterm = child.lua_get("Nuiterm.terminals.editor['1']")
  term_exists = bterm ~= vim.NIL
  equals(term_exists, true)

  -- Ensure buffer and editor term are the same
  local terms_equal = table.concat(bterm) == table.concat(eterm)
  equals(terms_equal, true)
end

T["bind_select"] = function()
  init_term()

  -- Get bufnr of file
  local fbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Create terminal
  child.cmd("Nuiterm type=editor num=1")

  -- Get bufnr of terminal
  local term_exists = child.lua_get("Nuiterm.terminals.editor['1']") ~= vim.NIL
  equals(term_exists, true)

  -- Hide and bind file (using menu selection)
  child.cmd("Nuiterm")
  child.lua("Nuiterm.bind_buf_to_terminal()")
  child.type_keys("<cr>")
  local bterm = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']")
  local eterm = child.lua_get("Nuiterm.terminals.editor['1']")
  term_exists = bterm ~= vim.NIL
  equals(term_exists, true)

  -- Ensure buffer and editor term are the same
  local terms_equal = table.concat(bterm) == table.concat(eterm)
  equals(terms_equal, true)
end

return T
