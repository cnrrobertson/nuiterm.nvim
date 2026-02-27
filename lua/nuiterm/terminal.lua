local Split = require("nui.split")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event
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
---@field type_id string id number of terminal as string (specific to type)
---@field ui table ui details for terminal
---@field ui.type string type of nui object to use for window
---@field ui.options table nui.object terminal nui options
---@field ui.num_layout integer which layout the terminal should be in
---@field windows table map of tabpage -> NUI window object
local Terminal = {}
local init_funcs = {}

--- Create new terminal object
---
---@param options table|nil config options for terminal (see |Nuiterm.config|)
function Terminal:new(options)
  -- Given or default options
  options = options or {}
  options = vim.tbl_deep_extend("force",Nuiterm.config,options)
  self.__index = self

  -- Populate options
  options.type = options.type
  options.cwd = init_funcs.get_term_cwd(options)
  options.type_id = init_funcs.get_type_id(options)
  options.type_name = init_funcs.generate_type_name(options)
  options.bufname = "nuiterm:" .. options.type .. ":" .. options.type_id
  options.repl = false

  -- UI options
  options.ui = {
    type = options.ui.type,
    options = init_funcs.get_ui_opts(options.ui.type),
    num_layout = 1
  }

  -- Window storage (keyed by tabpage)
  options.windows = {}

  -- Create terminal
  local term = setmetatable(options,self)
  Nuiterm.terminals[options.type][options.type_id] = term
  return term
end

--- Get type id
---
---@param options table terminal options table
function init_funcs.get_type_id(options)
  local type_id = nil
  if not options.type_id then
    type_id = utils.get_type_id(options.type)
  else
    type_id = tostring(options.type_id)
  end
  return type_id
end

--- Create type name for terminal (if tied to buffer)
---
---@param options table terminal options table
function init_funcs.generate_type_name(options)
  local type_name = nil
  if options.type == "buffer" then
    type_name = vim.api.nvim_buf_get_name(tonumber(options.type_id))
  elseif options.type == "window" then
    if not vim.api.nvim_win_is_valid(tonumber(options.type_id)) then
      error("Invalid window")
    end
  elseif options.type == "tab" then
    if not vim.api.nvim_tabpage_is_valid(tonumber(options.type_id)) then
      error("Invalid tabpage")
    end
  end
  return type_name
end

--- Get term cwd
---
---@param options table terminal options table
function init_funcs.get_term_cwd(options)
  local cwd = nil
  if options.open_at_cur_buf then
    cwd = vim.fn.expand("%:p:h")
  end
  return cwd
end

--- Get UI options
---
---@param ui_type string terminal ui style
function init_funcs.get_ui_opts(ui_type)
  local object_opts = {}
  local nui_opts = Nuiterm.config.ui.nui_opts
  if ui_type == "split" then
    local style_opts = Nuiterm.config.ui.default_layouts.split[1]
    object_opts = vim.tbl_deep_extend("force",nui_opts,style_opts)
  else
    local style_opts = Nuiterm.config.ui.default_layouts.popup[1]
    object_opts = vim.tbl_deep_extend("force",nui_opts,style_opts)
  end
  return object_opts
end

--- Create keymaps in terminal buffer
---
---@param tpage number|nil tabpage to set keymaps on (defaults to current)
function Terminal:set_keymaps(tpage)
  tpage = tpage or vim.api.nvim_get_current_tabpage()
  if self.keymaps and self.windows[tpage] then
    for _,km in pairs(self.keymaps) do
      self.windows[tpage]:map(unpack(km))
    end
  end
end

--- Create a NUI window for this terminal on the given tabpage
---
---@param tpage number|nil tabpage to create window on (defaults to current)
function Terminal:create_window(tpage)
  tpage = tpage or vim.api.nvim_get_current_tabpage()

  if (self.ui.type == "popup") or (self.ui.type == "float") then
    self.windows[tpage] = Popup(self.ui.options)
  else
    self.windows[tpage] = Split(self.ui.options)
  end

  self.windows[tpage]:mount()
  vim.api.nvim_win_set_option(self.windows[tpage].winid,"number",false)
  vim.api.nvim_win_set_buf(self.windows[tpage].winid, self.bufnr)
  self.windows[tpage].bufnr = self.bufnr

  -- Save window info on leave
  local win = self.windows[tpage]
  local term = self
  win:on({event.WinLeave}, function()
    if not win.winid or not vim.api.nvim_win_is_valid(win.winid) then
      return
    end
    if Nuiterm.config.persist_size then
      if win._.size.width then
        term.ui.width = vim.api.nvim_win_get_width(win.winid)
      end
      if win._.size.height then
        term.ui.height = vim.api.nvim_win_get_height(win.winid)
      end
    end
    if Nuiterm.config.hide_on_leave then
      win:hide()
      term.windows[tpage] = nil
    end
  end, {})
end

--- Show the terminal window
---
---@param focus boolean|nil whether to put cursor in terminal when showing
---@param cmd string|nil cmd to run immediately in terminal (if not shown before)
function Terminal:show(focus,cmd)
  local start_win = vim.api.nvim_get_current_win()
  local start_cursor = vim.api.nvim_win_get_cursor(start_win)
  local tpage = vim.api.nvim_get_current_tabpage()

  -- Ensure terminal buffer exists
  if self:ismounted() == false then
    self:mount(cmd)
  end

  -- Already shown on this tabpage - just focus if needed
  if self:isshown_on_tabpage(tpage) then
    if focus then
      vim.api.nvim_set_current_win(self.windows[tpage].winid)
    end
    return
  end

  -- Create window for this terminal on this tabpage
  self:create_window(tpage)

  -- Set keymaps
  self:set_keymaps(tpage)

  -- Update layout with persisted size if available
  local layout = self.windows[tpage].layout
  if layout then
    if self.ui.width then
      layout.size.width = self.ui.width
    end
    if self.ui.height then
      layout.size.height = self.ui.height
    end
    self.windows[tpage]:update_layout(layout)
  elseif self.ui.width or self.ui.height then
    local size = {}
    if self.ui.width then size.width = self.ui.width end
    if self.ui.height then size.height = self.ui.height end
    pcall(function() self.windows[tpage]:update_layout({size = size}) end)
  end

  -- Scroll terminal to bottom
  local buf_len = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_win_set_cursor(self.windows[tpage].winid, {buf_len, 0})

  -- Set cursor focus
  if focus then
    vim.api.nvim_set_current_win(self.windows[tpage].winid)
  else
    vim.api.nvim_set_current_win(start_win)
    vim.api.nvim_win_set_cursor(start_win,start_cursor)
  end
end

--- Create a terminal buffer
---
---@param cmd string|nil cmd to send to the terminal upon mounting
function Terminal:mount(cmd)
  if not self.bufnr then
    self.bufnr = vim.api.nvim_create_buf(false,false)
    local term_cmd = cmd or vim.o.shell
    self.chan = vim.api.nvim_buf_call(self.bufnr, function()
      return vim.fn.termopen(term_cmd, {
        -- Ensure terminal object is destroyed when closed
        on_exit=function()
          vim.api.nvim_feedkeys("0", "n", true)
          self.bufnr = nil
          self:unmount()
        end,
        cwd=self.cwd
      })
    end)
    vim.api.nvim_buf_set_option(self.bufnr,"filetype","terminal")
    utils.rename_buffer(self.bufnr,self.bufname)
  end
end

--- Hide terminal on current tabpage
---
function Terminal:hide()
  local tpage = vim.api.nvim_get_current_tabpage()
  self:hide_on_tabpage(tpage)
end

--- Hide terminal on specific tabpage
---
---@param tpage number tabpage to hide on
function Terminal:hide_on_tabpage(tpage)
  if self:isshown_on_tabpage(tpage) then
    self.windows[tpage]:hide()
    self.windows[tpage] = nil
  end
end

--- Hide terminal on all tabpages
---
function Terminal:hide_all()
  for tpage,_ in pairs(self.windows) do
    self:hide_on_tabpage(tpage)
  end
end

--- Unmount the terminal
---
function Terminal:unmount()
  self:hide_all()
  Nuiterm.delete_terminal(self.type, self.type_id)
end

--- Send command to the terminal
---
---@param cmd string|nil command to run in terminal
function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

--- Check if terminal UI is displayed on current tabpage
---
function Terminal:isshown()
  local tpage = vim.api.nvim_get_current_tabpage()
  return self:isshown_on_tabpage(tpage)
end

--- Check if terminal UI is displayed on specific tabpage
---
---@param tpage number tabpage to check
function Terminal:isshown_on_tabpage(tpage)
  local win = self.windows[tpage]
  if win and win.winid then
    if vim.api.nvim_win_is_valid(win.winid) then
      return true
    else
      -- Window closed externally, clean up
      self.windows[tpage] = nil
    end
  end
  return false
end

--- Check if terminal UI is displayed on any tabpage
---
function Terminal:isshown_anywhere()
  for tpage,_ in pairs(self.windows) do
    if self:isshown_on_tabpage(tpage) then
      return true
    end
  end
  return false
end

--- Check if terminal UI is mounted
---
function Terminal:ismounted()
  return self.bufnr ~= nil
end

--- Change UI style of terminal
---
---@param style string split or popup
function Terminal:change_style(style)
  local was_shown = self:isshown()
  if was_shown then
    self:hide()
  end
  self.ui.type = style
  self.ui.options = init_funcs.get_ui_opts(style)
  if was_shown then
    self:show(true)
  end
end

--- Change UI layout of terminal
---
---@param layout table|nil see nui.popup:update_layout() for details
function Terminal:change_layout(layout)
  self.ui.options = layout
  local tpage = vim.api.nvim_get_current_tabpage()
  if self.windows[tpage] then
    self.windows[tpage]:update_layout(layout)
  end
end

return Terminal