local child = MiniTest.new_child_neovim()
local equals = MiniTest.expect.equality
local nequals = MiniTest.expect.no_equality
local errors = MiniTest.expect.error
local nerrors = MiniTest.expect.no_error
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
  child.cmd("Nuiterm")
end

T['show_term_on_attempt_destroy'] = function()
  init_term()
  child.loop.sleep(500)
  local screenshot1 = child.get_screenshot()

  -- Show menu, try to destroy, decide to show
  child.lua("Nuiterm.toggle_menu()")
  child.loop.sleep(100)

  child.type_keys("ds<cr>")
  local screenshot2 = child.get_screenshot()

  -- Ensure no changes (aside from bottom 2 rows)
  local sc1 = utils.stack_screenshot(screenshot1,nil,2)
  local sc2 = utils.stack_screenshot(screenshot2,nil,2)
  equals(sc1,sc2)

  -- Hide terminal
  child.cmd("Nuiterm")
  child.loop.sleep(500)

  -- Show menu, try to destroy, decide to show
  child.lua("Nuiterm.toggle_menu()")
  child.loop.sleep(100)

  child.type_keys("ds<cr>")
  local screenshot3 = child.get_screenshot()

  -- Ensure no changes (aside from bottom 2 rows)
  local sc3 = utils.stack_screenshot(screenshot3,nil,2)
  equals(sc1,sc3)
  equals(sc2,sc3)
end

return T
