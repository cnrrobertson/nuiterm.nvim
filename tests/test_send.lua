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

T['send_to_current_none_exists'] = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")

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

  -- Send to current terminal from new buffer
  child.cmd("e test2.py")
  child.cmd("lua Nuiterm.send('terminal two', 'current', nil, nil)")
  child.loop.sleep(100)

  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("terminal one", screenshot))
  equals(true, utils.is_in_screenshot("usercommand", screenshot))
  equals(true, utils.is_in_screenshot("terminal two", screenshot))

  child.lua('Nlen = require("nuiterm.utils").dict_length(Nuiterm.windows)')
  equals(1, child.lua_get('Nlen'))
end

T['send_line(s)_w_unecessary_whitespace'] = function()
  child.cmd("e test.py")
  child.lua([[require('nuiterm').setup({
    focus_on_open = false,
    focus_on_send = false
  })]])
  child.cmd("startinsert")
  child.type_keys("       echo 'hello1'")
  child.type_keys("<cr>")
  child.type_keys("    echo 'hello2'")
  child.cmd("stopinsert")
  child.type_keys("kk")

  -- Send one line to terminal
  child.loop.sleep(100)
  child.cmd("lua Nuiterm.send_line()")
  child.loop.sleep(100)

  -- Ensure leading spaces were removed on send
  local screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("echo 'hello1'", screenshot, 2))
  equals(true, utils.is_in_screenshot("       echo 'hello1'", screenshot, 1))

  -- Send two lines to terminal
  child.loop.sleep(100)
  child.cmd("lua Nuiterm.send_lines(1, 2)")
  child.loop.sleep(100)

  -- Ensure leading spaces were removed on send (from both!)
  screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("       echo 'hello1'", screenshot, 1))
  equals(true, utils.is_in_screenshot("           echo 'hello2'", screenshot, 1))
  equals(true, utils.is_in_screenshot("    echo 'hello2'", screenshot, 2))
end

child.stop()
return T
