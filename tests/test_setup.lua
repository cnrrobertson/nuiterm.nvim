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

child.stop()
return T
