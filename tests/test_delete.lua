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

local init_term = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")
end

T["unmount"] = function()
  init_term()

  -- Get bufnr of file
  local fbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Create terminal
  child.cmd("Nuiterm")

  -- Get bufnr of terminal
  local tbufnr = child.lua_get("vim.api.nvim_get_current_buf()")
  local term_exists = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']") ~= vim.NIL
  equals(term_exists, true)

  -- Delete terminal
  child.lua("Nuiterm.terminals.buffer['"..fbufnr.."']:unmount()")

  -- Ensure it is not in terminal list
  term_exists = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']") ~= vim.NIL
  equals(term_exists, false)

  -- Ensure buffer is not valid
  local tbuf_exists = child.lua_get("vim.api.nvim_buf_is_valid("..tbufnr..")")
  equals(tbuf_exists, false)
end

T["delete"] = function()
  init_term()

  -- Get bufnr of file
  local fbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Create terminal
  child.cmd("Nuiterm")

  -- Get bufnr of terminal
  local tbufnr = child.lua_get("vim.api.nvim_get_current_buf()")
  local term_exists = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']") ~= vim.NIL
  equals(term_exists, true)

  -- Delete terminal
  child.lua("Nuiterm.delete_terminal('buffer', "..fbufnr..")")

  -- Ensure it is not in terminal list
  term_exists = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']") ~= vim.NIL
  equals(term_exists, false)

  -- Ensure buffer is not valid
  local tbuf_exists = child.lua_get("vim.api.nvim_buf_is_valid("..tbufnr..")")
  equals(tbuf_exists, false)
end

T["delete_with_bind"] = function()
  init_term()

  -- Get bufnr of file
  local fbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Create terminal
  child.cmd("Nuiterm type=editor num=1")

  -- Get bufnr of terminal
  local tbufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Hide and bind file
  child.cmd("Nuiterm")
  child.lua("Nuiterm.bind_buf_to_terminal('editor', 1)")

  -- Delete terminal
  child.lua("Nuiterm.delete_terminal('editor', 1)")

  -- Ensure neither is in terminal list
  local bterm = child.lua_get("Nuiterm.terminals.buffer['"..fbufnr.."']")
  local eterm = child.lua_get("Nuiterm.terminals.editor['1']")
  local term_exists = eterm ~= vim.NIL
  equals(term_exists, false)
  term_exists = bterm ~= vim.NIL
  equals(term_exists, false)

  -- Ensure buffer is not valid
  local tbuf_exists = child.lua_get("vim.api.nvim_buf_is_valid("..tbufnr..")")
  equals(tbuf_exists, false)
end

child.stop()
return T
