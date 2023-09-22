local Split = require("nui.split")
local Popup = require("nui.Popup")
local config = require("nuiterm.config")
local utils = require("nuiterm.utils")
local Terminal = {}

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
    mounted = false,
    shown = false,
    object = ui_object
  }
  local term = setmetatable(options,self)
  Nuiterm.terminals[options.type][options.type_id] = term
  return term
end

function Terminal:set_keymaps()
  if self.keymaps then
    for _,km in pairs(self.keymaps) do
      self.ui.object:map(unpack(km))
    end
  end
end

function Terminal:show(focus,cmd)
  local start_win = vim.api.nvim_get_current_win()
  local start_cursor = vim.api.nvim_win_get_cursor(start_win)
  if self.ui.mounted == false then
    self.ui.object:mount()
    self.ui.mounted = true
    self.ui.shown = true
    if self.bufnr == nil then
      self.bufnr = vim.api.nvim_create_buf(false,false)
    end
    self:set_keymaps()
    vim.api.nvim_win_set_buf(0,self.bufnr)
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
    vim.api.nvim_win_set_option(0,"number",false)
    vim.api.nvim_buf_set_name(self.bufnr,self.bufname)
    if focus then
      -- Ensure insert mode on mount
      vim.api.nvim_feedkeys("i",'t',false)
    end
  elseif self.ui.shown == false then
    self.ui.object:show()
    vim.api.nvim_win_set_buf(0,self.bufnr)
    self.ui.shown = true
  end
  if not focus then
    vim.api.nvim_set_current_win(start_win)
    vim.api.nvim_win_set_cursor(start_win,start_cursor)
  end
end

function Terminal:hide()
  self.ui.object:hide()
  self.ui.shown = false
end

function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

return Terminal
