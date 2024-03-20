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

T['autocmds'] = function()
  child.lua("require('nuiterm').setup()")
  local autocmds = child.api.nvim_get_autocmds({group="Nuiterm"})
  equals(4, #autocmds)
end

T['usercmds'] = function()
  child.lua("require('nuiterm').setup()")
  local usercmds = child.api.nvim_get_commands({})
  local num_ucmds = 0
  for _,v in pairs(usercmds) do
    if string.find(v.name, "Nuiterm") then
      num_ucmds = num_ucmds + 1
    end
  end
  equals(num_ucmds, 7)
end

T['fixed_buffer_in_window'] = function()
  child.cmd("e test.py")
  child.lua([[require('nuiterm').setup({
    focus_on_open = true,
    terminal_win_fixed = true,
  })]])

  child.cmd("Nuiterm")
  child.loop.sleep(100)
  child.cmd("bnext")
  nequals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)
  child.cmd("bprev")
  nequals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)

  -- Allow for changing buffer in window
  child.lua([[require('nuiterm').setup({
    focus_on_open = true,
    terminal_win_fixed = false,
  })]])
  child.cmd("bnext")
  equals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)
end

child.stop()
return T
