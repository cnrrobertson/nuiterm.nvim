local Menu = require("nui.menu")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local utils = require("nuiterm.utils")
local menu = {}

function menu.resize_bufname(buf_name)
    local buf_parts = {}
    for part in buf_name:gmatch("([^/]+)/?") do table.insert(buf_parts, part) end
    local num_parts = #buf_parts
    buf_parts = {unpack(buf_parts, num_parts-Nuiterm.config.ui.menu_buf_depth, num_parts)}
    return table.concat(buf_parts, "/")
end

function menu.add_editor_terms(lines,remove_header)
  local editor_terms = utils.get_mounted("editor")
  if utils.dict_length(editor_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("", {char=""})
      lines[#lines+1] = Menu.separator("Editor", {text_align = "left"})
    end
    for _,t in pairs(editor_terms) do
      local pre_str = ""
      if t:isshown() then
        pre_str = "* "
      end
      local display = pre_str..t.type_id
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_tab_terms(lines,remove_header)
  local tab_terms = utils.get_mounted("tab")
  if utils.dict_length(tab_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("", {char=""})
      lines[#lines+1] = Menu.separator("Tab", {text_align = "left"})
    end
    for _,t in pairs(tab_terms) do
      local buf_names = ""
      for _,win in pairs(vim.api.nvim_tabpage_list_wins(tonumber(t.type_id))) do
        local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
        buf_name = menu.resize_bufname(buf_name)
        buf_names = buf_names.." "..buf_name
      end
      local pre_str = ""
      if t:isshown() then
        pre_str = "* "
      end
      local display = pre_str..t.type_id..": "..buf_names
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_window_terms(lines,remove_header)
  local window_terms = utils.get_mounted("window")
  if utils.dict_length(window_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("", {char=""})
      lines[#lines+1] = Menu.separator("Window", {text_align = "left"})
    end
    for _,t in pairs(window_terms) do
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(tonumber(t.type_id)))
      buf_name = menu.resize_bufname(buf_name)
      local pre_str = ""
      if t:isshown() then
        pre_str = "* "
      end
      local display = pre_str..t.type_id..": "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_buffer_terms(lines,remove_header)
  local buffer_terms = utils.get_mounted("buffer")
  if utils.dict_length(buffer_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("", {char=""})
      lines[#lines+1] = Menu.separator("Buffer", {text_align = "left"})
    end
    for _,t in pairs(buffer_terms) do
      local buf_name = t.type_name
      buf_name = menu.resize_bufname(buf_name)
      local pre_str = ""
      if t:isshown() then
        pre_str = "* "
      end
      local display = pre_str..t.type_id..": "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.set_mappings(keys)
  for _,k in ipairs(keys.new) do
    Nuiterm.terminal_menu:map("n", k, menu.new_terminal, {noremap=true})
  end
  for _,k in ipairs(keys.destroy) do
    Nuiterm.terminal_menu:map("n", k, menu.destroy_terminal, {noremap=true})
  end
end

function menu.set_autocmds()
  -- Close terminal
  Nuiterm.terminal_menu:on({event.BufLeave}, function()
    Nuiterm.terminal_menu:unmount()
  end, {once = true})
end

function menu.new_terminal()
  local type = nil
  local type_id = nil
  local cmd = nil
  local input_opts = {
    relative = "cursor",
    position = {row = 1, col = 0},
    size = 50,
    zindex = 600,
    border = {style = "rounded", text = {top = "Type (buffer, window, tab, editor)", top_align = "left"}},
  }
  local input = Input(input_opts, {
    on_submit = function(value)
      if value == "" then type = nil else type = value end
      input_opts.border.text.top = "Type ID"
      local input = Input(input_opts, {
        on_submit = function(value2)
          if value2 == "" then type_id = nil else type_id = value2 end
          input_opts.border.text.top = "Command"
          local input = Input(input_opts, {
            on_submit = function(value3)
              if value3 == "" then cmd = nil else cmd = value2 end
              Nuiterm.terminal_menu:unmount()
              Nuiterm.toggle(type, type_id, cmd)
            end,
          })
          input:mount()
        end,
      })
      input:mount()
    end
  })
  input:mount()
end

function menu.destroy_terminal()
  local tree = Nuiterm.terminal_menu.tree
  local node = tree:get_node()
  local term = Nuiterm.terminals[node.type][node.type_id]
  if Nuiterm.config.ui.menu_confirm_destroy then
    vim.ui.input({prompt = "Destroy terminal? (y/n/[s]how) "}, function(input)
      if input == "y" then
        term:unmount()
        tree:remove_node(node._id)
        tree:render()
      elseif input == "" or input == "s" or input == "show" then
        term:show(Nuiterm.config.focus_on_open)
      end
    end)
  end
end

return menu
