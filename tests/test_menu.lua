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

local is_term_shown = function()
  child.lua([[
    _G._chk = false
    for _,group in pairs(Nuiterm.terminals) do
      for _,term in pairs(group) do
        if term.isshown and term:isshown() then _G._chk = true end
      end
    end
  ]])
  return child.lua_get('_G._chk')
end

local is_term_mounted = function()
  child.lua([[
    _G._chk = false
    for _,group in pairs(Nuiterm.terminals) do
      for _,term in pairs(group) do
        if term.ismounted and term:ismounted() then _G._chk = true end
      end
    end
  ]])
  return child.lua_get('_G._chk')
end

T['menu_populated'] = function()
  init_term()

  -- TODO: Test if each of the buffer, window, tab, editor terminals are added
end

T['menu_populated_with_bind'] = function()
  init_term()

  -- TODO: Ensure no duplicates are added if buffer is bound
end

T['show_term_on_attempt_destroy'] = function()
  init_term()
  child.loop.sleep(500)

  -- Terminal should be shown and mounted
  equals(true, is_term_shown())
  equals(true, is_term_mounted())

  -- Show menu, try to destroy, decide to show
  child.lua("Nuiterm.toggle_menu()")
  child.loop.sleep(100)

  child.type_keys("ds<cr>")
  child.loop.sleep(100)

  -- Terminal should still be shown and mounted (chose "show" not "yes")
  equals(true, is_term_shown())
  equals(true, is_term_mounted())

  -- Hide terminal
  child.cmd("Nuiterm")
  child.loop.sleep(500)

  equals(false, is_term_shown())
  equals(true, is_term_mounted())

  -- Show menu, try to destroy, decide to show
  child.lua("Nuiterm.toggle_menu()")
  child.loop.sleep(100)

  child.type_keys("ds<cr>")
  child.loop.sleep(100)

  -- Terminal should be shown again (chose "show")
  equals(true, is_term_shown())
  equals(true, is_term_mounted())
end

return T