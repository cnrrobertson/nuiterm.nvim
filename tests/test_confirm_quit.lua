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

local init_terms = function()
  child.cmd("e test.py")
  child.lua("require('nuiterm').setup()")
  child.lua("Nuiterm.config.confirm_quit = true")
  child.cmd("Nuiterm")
  child.cmd("Nuiterm")
end

T['confirm_prompt'] = function()
  init_terms()
  child.type_keys(":q<cr>")
  equals(child.fn.mode(), "c")
end

T['confirm_dont_close'] = function()
  init_terms()
  child.type_keys(":q<cr>")
  child.type_keys("n<cr>")
  equals(child.is_running(), true)
end

T['confirm_show'] = function()
  init_terms()
  child.type_keys(":q<cr>")
  child.type_keys("s<cr>")
  equals(child.is_running(), true)
  -- Check we are in floating window (menu)
  nequals(child.api.nvim_win_get_config(0).relative, '')
end

-- TODO: Figure out some way to ensure nvim is closed with 'y'
-- T['confirm_close'] = function()
--   init_terms()
--   child.type_keys(":q<cr>")
--   child.type_keys("y<cr>")
-- end

child.stop()
return T
