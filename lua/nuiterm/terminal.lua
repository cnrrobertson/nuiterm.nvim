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
function Terminal:set_keymaps()
  local tpage = vim.api.nvim_get_current_tabpage()
  if self.keymaps then
    for _,km in pairs(self.keymaps) do
      Nuiterm.windows[tpage]:map(unpack(km))
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
  -- Enusre terminal buffer exists
  if self:ismounted() == false then
    self:mount(cmd)
  end

  -- Enusre terminal buffer is displayed
  local tpage = vim.api.nvim_get_current_tabpage()
  if Nuiterm.windows[tpage] == nil then
    Nuiterm.create_term_win(self.ui)
  end
  Nuiterm.show_term_win(self)

  -- Set keymaps
  self:set_keymaps()

  -- Set layout
  local layout = Nuiterm.windows[tpage].layout
  if self.ui.width then
    layout.size.width = self.ui.width
  end
  if self.ui.height then
    layout.size.height = self.ui.height
  end
  Nuiterm.windows[tpage]:update_layout(layout)

  -- Set cursor focus
  if focus then
    vim.api.nvim_set_current_win(Nuiterm.windows[tpage].winid)
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

--- Unmount the terminal
---
function Terminal:unmount()
  local tpage = vim.api.nvim_get_current_tabpage()
  if Nuiterm.windows[tpage] then
    if Nuiterm.windows[tpage].bufnr == self.bufnr then
      Nuiterm.hide_all_terms()
      Nuiterm.windows[tpage].bufnr = nil
    end
  end
  Nuiterm.delete_terminal(self.type, self.type_id)
end

--- Send command to the terminal
---
---@param cmd string|nil command to run in terminal
function Terminal:send(cmd)
  vim.api.nvim_chan_send(self.chan, cmd)
end

--- Check if terminal UI is displayed
---
function Terminal:isshown()
  local tpage = vim.api.nvim_get_current_tabpage()
  if Nuiterm.windows[tpage] then
    if Nuiterm.windows[tpage].winid then
      if self.bufnr == Nuiterm.windows[tpage].bufnr then
        return true
      end
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
    Nuiterm.hide_all_terms()
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
  Nuiterm.windows[tpage]:update_layout(layout)
end

return Terminal





