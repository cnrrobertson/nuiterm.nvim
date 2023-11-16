local Split = require("nui.split")
local Popup = require("nui.popup")
local utils = require("nuiterm.utils")
local event = require("nui.utils.autocmd").event

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
---@field type_id string id number of terminal as string (specific to type)
---@field ui table ui details for terminal
---@field ui.type string type of nui object to use for window
---@field ui.object nui.object terminal nui object
local Terminal = {}

--- Create new terminal object
---
---@param options table|nil config options for terminal (see |Nuiterm.config|)
function Terminal:new(options)
  options = options or {}
  options = vim.tbl_deep_extend("force",Nuiterm.config,options)
  self.__index = self
  options.type = options.type
  if not options.open_at_cwd then
    options.cwd = vim.fn.expand("%:p:h")
  end
  if not options.type_id then
    options.type_id = utils.get_type_id(options.type)
  else
    options.type_id = tostring(options.type_id)
  end
  if options.type == "buffer" then
    options.type_name = vim.api.nvim_buf_get_name(tonumber(options.type_id))
  end
  options.bufname = "nuiterm:" .. options.type .. ":" .. options.type_id
  options.repl = false
  local ui_object = {}
  if options.ui.type == "split" then
    ui_object = Split(options.ui.split_opts)
  else
    ui_object = Popup(options.ui.popup_opts)
  end
  options.ui = {
    type = options.ui.type,
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
---@param cmd string|nil cmd to run immediately in terminal (if not shown before)
function Terminal:show(focus,cmd)
  local start_win = vim.api.nvim_get_current_win()
  local start_cursor = vim.api.nvim_win_get_cursor(start_win)
  if self.ui.object._.mounted == false then
    self:mount(cmd)
  elseif self.ui.object.winid == nil then
    self.ui.object:show()
  end
  if Nuiterm.config.hide_on_leave then
    self.ui.object:on({event.WinLeave}, function()
      self:hide(Nuiterm.config.persist_size)
    end, {})
  end
  if not focus then
    vim.cmd[[stopinsert]]
    vim.api.nvim_set_current_win(start_win)
    vim.api.nvim_win_set_cursor(start_win,start_cursor)
  end
end

--- Mount the terminal
---
---@param cmd string|nil cmd to send to the terminal upon mounting
function Terminal:mount(cmd)
  if self.bufnr then
    self.ui.object.bufnr = self.bufnr
    self.ui.object:mount()
  else
    self.ui.object:mount()
    self.bufnr = self.ui.object.bufnr
    self:set_keymaps()
    local term_cmd = cmd or vim.o.shell
    self.chan = vim.fn.termopen(term_cmd, {
      on_exit=function()
        self:unmount(); self.bufnr = nil
      end,
      cwd=self.cwd
    })
    vim.api.nvim_buf_set_option(self.ui.object.bufnr,"filetype","terminal")
    vim.api.nvim_buf_set_name(self.ui.object.bufnr,self.bufname)
    vim.api.nvim_win_set_option(self.ui.object.winid,"number",false)
  end
end

--- Unmount the terminal
---
function Terminal:unmount()
    self.ui.object:unmount()
    self.bufnr = nil
    Nuiterm.terminals[self.type][self.type_id] = nil
end

--- Hide the terminal
---
---@param persist_size boolean|nil whether to save changes to window size
function Terminal:hide(persist_size)
  if persist_size then
    if self.ui.object._.size.width then
      local new_width = vim.api.nvim_win_get_width(self.ui.object.winid)
      self.ui.object._.size.width = new_width
      self.ui.object._.win_config.width = new_width
    end
    if self.ui.object._.size.height then
      local new_height = vim.api.nvim_win_get_height(self.ui.object.winid)
      self.ui.object._.size.height = new_height
      self.ui.object._.win_config.height = new_height
    end
  end
  self.ui.object:hide()
end

--- Send command to the terminal
---
---@param cmd string|nil command to run in terminal
function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

return Terminal
