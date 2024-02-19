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

T['send_to_buffer_term'] = function()
  init_term()

  -- Send to buffer terminal
  child.loop.sleep(500)
  child.cmd("lua Nuiterm.send('buffer term', 'current', nil, nil)")
  child.loop.sleep(100)

  local screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("buffer term", screenshot))

  child.cmd("NuitermSend cmd=usercommand")
  child.loop.sleep(100)

  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("usercommand", screenshot))
end

T['send_to_current'] = function()
  init_term()

  -- Change window/buffer
  child.api.nvim_set_current_win(1000)
  child.cmd("e test2.py")

  -- Send to current terminal
  child.loop.sleep(500)
  child.cmd("lua Nuiterm.send('terminal one', 'current', nil, nil)")
  child.loop.sleep(100)

  local screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("terminal one", screenshot))

  child.cmd("NuitermSend type=current cmd=usercommand")
  child.loop.sleep(100)

  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("usercommand", screenshot))

  -- Send to personal terminal
  child.cmd("lua Nuiterm.send('terminal two', nil, nil, nil)")
  child.loop.sleep(100)

  screenshot = child.get_screenshot()
  nequals(true, utils.is_in_screenshot("terminal one", screenshot))
  nequals(true, utils.is_in_screenshot("usercommand", screenshot))
  equals(true, utils.is_in_screenshot("terminal two", screenshot))
end

child.stop()
return T
