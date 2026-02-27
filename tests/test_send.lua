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

  equals(true, utils.is_in_term_buf(child, "buffer term"))

  child.cmd("NuitermSend cmd=usercommand")

  equals(true, utils.is_in_term_buf(child, "usercommand"))
end

T['send_to_current'] = function()
  init_term()

  -- Change window/buffer
  child.api.nvim_set_current_win(1000)
  child.cmd("e test2.py")

  -- Send to current terminal
  child.loop.sleep(500)
  child.cmd("lua Nuiterm.send('terminal one', 'current', nil, nil)")

  equals(true, utils.is_in_term_buf(child, "terminal one"))

  child.cmd("NuitermSend type=current cmd=usercommand")

  equals(true, utils.is_in_term_buf(child, "usercommand"))

  -- Send to personal terminal (both terminals visible with exclusive_mode off)
  child.cmd("lua Nuiterm.send('terminal two', nil, nil, nil)")

  -- The new buffer terminal for test2.py should have "terminal two"
  local test2_bufnr = child.lua_get("vim.api.nvim_get_current_buf()")
  equals(true, utils.is_in_term_buf(child, "terminal two", "buffer", tostring(test2_bufnr)))
end

T['send_to_current_none_exists'] = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")

  -- Send to current terminal
  child.loop.sleep(500)
  child.cmd("lua Nuiterm.send('terminal one', 'current', nil, nil)")

  equals(true, utils.is_in_term_buf(child, "terminal one"))

  child.cmd("NuitermSend type=current cmd=usercommand")

  equals(true, utils.is_in_term_buf(child, "usercommand"))

  -- Send to current terminal from new buffer (same terminal since "current" resolves to shown)
  child.cmd("e test2.py")
  child.cmd("lua Nuiterm.send('terminal two', 'current', nil, nil)")

  -- All three should be in the same terminal buffer
  equals(true, utils.is_in_term_buf(child, "terminal one"))
  equals(true, utils.is_in_term_buf(child, "usercommand"))
  equals(true, utils.is_in_term_buf(child, "terminal two"))

  child.lua('Nlen = #Nuiterm.get_visible_terms()')
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

  -- Ensure leading spaces were removed on send (text in terminal buf without leading spaces)
  equals(true, utils.is_in_term_buf(child, "echo 'hello1'"))

  -- The source buffer should still have the leading whitespace
  local screenshot = child.get_screenshot()
  equals(true, utils.is_in_screenshot("       echo 'hello1'", screenshot, 1))

  -- Send two lines to terminal
  child.loop.sleep(100)
  child.cmd("lua Nuiterm.send_lines(1, 2)")
  child.loop.sleep(100)

  -- Both lines should be in the terminal buffer
  equals(true, utils.is_in_term_buf(child, "echo 'hello1'"))
  equals(true, utils.is_in_term_buf(child, "echo 'hello2'"))
end

child.stop()
return T