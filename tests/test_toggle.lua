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

local in_term = function()
  nequals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)
end

local not_in_term = function()
  equals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)
end

T['toggle_default'] = function()
  init_term()

  -- Buffer correctly named
  nequals(string.find(child.api.nvim_buf_get_name(0), "nuiterm:"), nil)

  -- Default type nuiterm
  nequals(string.find(child.api.nvim_buf_get_name(0), "buffer"), nil)

  -- Buffer has active terminal
  equals(child.fn.mode(), "t")

  -- Buffer number correct
  local term_name = child.api.nvim_buf_get_name(0)
  child.cmd("Nuiterm")
  local term_num = child.api.nvim_get_current_buf()
  nequals(string.find(term_name, term_num), nil)
end

T['toggle_cmd'] = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")

  -- Check command runs
  child.cmd("Nuiterm cmd=python3")

  -- Toggle with new command, ensure doesn't run
  child.cmd("Nuiterm cmd=error")

  -- TODO: Improve this test
end

T['toggle_show_hide'] = function()
  init_term()

  in_term()
  child.cmd("Nuiterm")
  not_in_term()
end

T['toggle_incorrect'] = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")

  -- Catch incorrect numbers (if buffer doesnt exist etc.)
  errors(function() child.cmd("Nuiterm type=buffer num=100") end)
  nerrors(function() child.cmd("Nuiterm type=buffer num=1") end)
  child.cmd("Nuiterm")
  errors(function() child.cmd("Nuiterm type=window num=100") end)
  nerrors(function() child.cmd("Nuiterm type=window num=1000") end)
  child.cmd("Nuiterm")
  errors(function() child.cmd("Nuiterm type=tab num=100") end)
  nerrors(function() child.cmd("Nuiterm type=tab num=1") end)
  child.cmd("Nuiterm")
  nerrors(function() child.cmd("Nuiterm type=editor num=1") end)
end

T['toggle_win_from_buf'] = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")

  child.cmd("Nuiterm type=buffer")
  in_term()
  nerrors(function() child.cmd("Nuiterm type=window") end)
  not_in_term()
end

T['toggle_hide_all'] = function()
  init_term()

  child.cmd("NuitermHideAll")

  nequals(string.find(child.api.nvim_buf_get_name(0), "test.py"), nil)
end

T['toggle_same_term_on_different_tabs'] = function()
  init_term()

  child.cmd("tabnew test.py")
  child.cmd("Nuiterm")
  child.loop.sleep(500)

  -- Send to terminal
  child.cmd("NuitermSend cmd=tab2")
  child.loop.sleep(100)
  local screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("tab2", screenshot))

  -- Change to new tab and also send to terminal
  child.cmd("tabprev")
  child.cmd("NuitermSend cmd=tab1")
  child.loop.sleep(100)
  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("tab2", screenshot))
  equals(true, utils.is_in_screenshot("tab1", screenshot))

  -- Hide terminals on tab 1
  child.cmd("Nuiterm")
  screenshot = child.get_screenshot()
  nequals(true, utils.is_in_screenshot("tab2", screenshot))
  nequals(true, utils.is_in_screenshot("tab1", screenshot))

  -- Move to tab 2 and ensure both commmands are present
  child.cmd("tabnext")
  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("tab2", screenshot))
  equals(true, utils.is_in_screenshot("tab1", screenshot))
end

child.stop()
return T
