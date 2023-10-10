local Split = require("nui.split")
local Popup = require("nui.Popup")
local config = require("nuiterm.config")
local utils = require("nuiterm.utils")

---@tag Terminal
---@signature Terminal
---
---@class Terminal
---
---@field bufname string name of terminal buffer (uses nuiterm:... pattern)
---@field bufnr integer buffer number of terminal buffer
---@field cwd string directory of terminal
---@field keymaps table table of keymaps that are set for terminal buffer
---@field repl boolean whether repl active or not (not currently used)
---@field type string type of terminal (see |Nuiterm.config|)
---@field type_id integer id number of terminal (specific to type)
---@field ui table ui details for terminal
---@field ui.type string type of nui object to use for window
---@field ui.shown boolean whether terminal buffer is being shown
---@field ui.object nui.object terminal nui object
local Terminal = {}

--- Create new terminal object
---
---@param options table|nil config options for terminal (see |Nuiterm.config|)
function Terminal:new(options)
  options = options or {}
  options = vim.tbl_deep_extend("force",config,options)
  self.__index = self
  options.type = options.type
  if not options.open_at_cwd then
    options.cwd = vim.fn.expand("%:p:h")
  end
  options.type_id = utils.get_type_id(options.type)
  options.bufnr = vim.api.nvim_create_buf(false,false)
  options.bufname = "nuiterm:" .. options.type .. ":" .. tostring(options.type_id)
  options.repl = false
  local ui_object = {}
  if options.ui.type == "split" then
    local bn = {bufnr = options.bufnr}
    local split_opts = vim.tbl_deep_extend("force",options.ui.split_opts,bn)
    ui_object = Split(split_opts)
  else
    local bn = {bufnr = options.bufnr}
    local popup_opts = vim.tbl_deep_extend("force",options.ui.popup_opts,bn)
    ui_object = Popup(popup_opts)
  end
  options.ui = {
    type = options.ui.type,
    shown = false,
    object = ui_object
  }
  local term = setmetatable(options,self)
  Nuiterm.terminals[options.type][options.type_id] = term
  return term
end

--- Create keymaps in terminal buffer
---
function Terminal:set_keymaps()
  if self.keymaps then
    for _,km in pairs(self.keymaps) do
      self.ui.object:map(unpack(km))
    end
  end
end

--- Show the terminal window
---
---@param focus boolean|nil whether to put cursor in terminal when showing
---@param cmd string|nil cmd to send to terminal upon showing
function Terminal:show(focus,cmd)
  local start_win = vim.api.nvim_get_current_win()
  local start_cursor = vim.api.nvim_win_get_cursor(start_win)
  if self.ui.object._.mounted == false then
    vim.wait(100,function()self.ui.object:mount()end)
    self.ui.shown = true
    if self.bufnr == nil then
      self.bufnr = vim.api.nvim_create_buf(false,false)
    end
    self:set_keymaps()
    vim.api.nvim_win_set_buf(self.ui.object.winid,self.bufnr)
    if cmd then
      self.chan = vim.fn.termopen(cmd, {
        on_exit=function()vim.api.nvim_feedkeys("i","n","t")end,
        cwd=self.cwd
      })
    else
      self.chan = vim.fn.termopen(vim.o.shell, {
        on_exit=function()vim.api.nvim_feedkeys("i","n","t")end,
        cwd=self.cwd
      })
    end
    vim.api.nvim_buf_set_option(self.bufnr,"filetype","terminal")
    vim.api.nvim_win_set_option(self.ui.object.winid,"number",false)
    vim.api.nvim_buf_set_name(self.bufnr,self.bufname)
  elseif self.ui.shown == false then
    vim.wait(100,function()self.ui.object:show()end)
    vim.api.nvim_win_set_buf(0,self.bufnr)
    self.ui.shown = true
  end
  if not focus then
    vim.api.nvim_set_current_win(start_win)
    vim.api.nvim_win_set_cursor(start_win,start_cursor)
  end
end

--- Hide the terminal window
---
function Terminal:hide()
  vim.wait(100,function()self.ui.object:hide()end)
  self.ui.shown = false
end

--- Unmount the terminal window
---
function Terminal:unmount()
  vim.wait(100,function()self.ui.object:unmount()end)
  self.ui.shown = false
end

--- Send command to the terminal
---
---@param cmd string|nil command to run in terminal
function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

return Terminal
