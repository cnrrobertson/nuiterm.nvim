local Menu = require("nui.menu")
local utils = require("nuiterm.utils")
local menu = {}

menu.menu_options = {
 relative = "editor",
  position = '50%',
  size = '50%',
  border = {
    style = "rounded",
    text = {
      top = "Terminal Menu",
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal",
  }
}

function menu.get_mounted_terms(group)
  local terms = {}
  for _,t in pairs(Nuiterms[group]) do
    if t.ui.mounted == true then
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
      local display = "Editor "..t.type_id
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
      for _,win in pairs(vim.api.nvim_tabpage_list_wins(t.type_id)) do
        buf_names = buf_names.." "..vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      end
      local display = "Tab "..t.type_id.."- Buffers in tab: "..buf_names
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
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(t.type_id))
      local display = "Window "..t.type_id.."- Buffer in window: "..buf_name
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
      local buf_name = vim.api.nvim_buf_get_name(t.type_id)
      local display = "Buffer "..t.type_id..": "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
end

return menu
