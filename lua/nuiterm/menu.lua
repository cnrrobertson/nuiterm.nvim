local Menu = require("nui.menu")
local event = require("nui.utils.autocmd").event
local utils = require("nuiterm.utils")
local menu = {}

function menu.get_mounted_terms(group)
  local terms = {}
  for _,t in pairs(Nuiterm.terminals[group]) do
    if t.ui.object._.mounted == true then
      table.insert(terms, t)
    end
  end
  return terms
end

function menu.add_editor_terms(lines,remove_header)
  local editor_terms = menu.get_mounted_terms("editor")
  if utils.table_length(editor_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("Editor")
    end
    for _,t in pairs(editor_terms) do
      local pre_str = ""
      if t.ui.object.winid then
        pre_str = "* "
      end
      local display = pre_str.."Editor "..t.type_id
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_tab_terms(lines,remove_header)
  local tab_terms = menu.get_mounted_terms("tab")
  if utils.table_length(tab_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("Tab")
    end
    for _,t in pairs(tab_terms) do
      local buf_names = ""
      for _,win in pairs(vim.api.nvim_tabpage_list_wins(tonumber(t.type_id))) do
        buf_names = buf_names.." "..vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      end
      local pre_str = ""
      if t.ui.object.winid then
        pre_str = "* "
      end
      local display = pre_str.."Tab "..t.type_id.." - Buffers in tab: "..buf_names
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_window_terms(lines,remove_header)
  local window_terms = menu.get_mounted_terms("window")
  if utils.table_length(window_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("Window")
    end
    for _,t in pairs(window_terms) do
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(tonumber(t.type_id)))
      local pre_str = ""
      if t.ui.object.winid then
        pre_str = "* "
      end
      local display = pre_str.."Window "..t.type_id.." - Buffer in window: "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.add_buffer_terms(lines,remove_header)
  local buffer_terms = menu.get_mounted_terms("buffer")
  if utils.table_length(buffer_terms) > 0 then
    if not remove_header then
      lines[#lines+1] = Menu.separator("Buffer")
    end
    for _,t in pairs(buffer_terms) do
      local buf_name = t.type_name
      local pre_str = ""
      if t.ui.object.winid then
        pre_str = "* "
      end
      local display = pre_str.."Buffer "..t.type_id..": "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

function menu.set_mappings()
  -- Close terminal
  Nuiterm.terminal_menu:map("n", "d", function()
    local tree = Nuiterm.terminal_menu.tree
    local node = tree:get_node()
    local term = Nuiterm.terminals[node.type][node.type_id]
    term:unmount()
    tree:remove_node(node._id)
    tree:render()
  end, {noremap=true})
  -- Show help
end

function menu.set_autocmds()
  -- Close terminal
  Nuiterm.terminal_menu:on({event.BufLeave}, function()
    Nuiterm.terminal_menu:unmount()
  end, {once = true})
end

return menu
