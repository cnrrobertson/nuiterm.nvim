-- Make tmp dir
local exists_tmp = vim.fn.isdirectory("tmp")
if exists_tmp == 0 then
  os.execute("mkdir tmp")
end

-- Installed needed plugins
local plugins = {"https://github.com/echasnovski/mini.nvim"}

for _,plugin in pairs(plugins) do
  local plugin_name = string.reverse(string.match(string.reverse(plugin), "([%w,\\.]+)/"))
  local exists_plugin = vim.fn.isdirectory("tmp/"..plugin_name)
  if exists_plugin == 0 then
    os.execute("git clone "..plugin.." tmp/"..plugin_name)
  end
end
vim.opt.rtp:append("tmp/mini.nvim")

-- Load plugins
local doc = require("mini.doc")
doc.setup()

-- Generate docs
doc.generate({"lua/nuiterm.lua", "lua/nuiterm/config.lua", "lua/nuiterm/terminal.lua"})
