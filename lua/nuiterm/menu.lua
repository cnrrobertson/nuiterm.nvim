local Layout = require("nui.layout")
local Text = require("nui.text")
local Line = require("nui.line")
local Menu = require("nui.menu")
local Popup = require("nui.popup")
local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local utils = require("nuiterm.utils")
local menu = {}

-------------------------------------------------------------------------------
-- Menu creation
-------------------------------------------------------------------------------
function menu.create_menu(lines, keys, on_submit)
  local terminal_menu = Menu({
      relative = "editor",
      size = "100%",
      position = 0,
      border = {
        style = "rounded",
        text = {
          top = "Terminals",
          top_align = "center",
          bottom_align = "left",
        },
      },
      win_options = {
        winhighlight = "Normal:Normal",
      }
    }, {
    zindex = 500,
    enter = true,
    lines = lines,
    max_width = 20,
    keymap = keys,
    on_submit = on_submit,
  })
  return terminal_menu
end

function menu.create_help(keys)
  local popup_opts = {
    position = 0,
    relative = "editor",
    size = "100%",
    border = {
      style = "double",
      text = {
        top = "Help",
        top_align = "center",
      },
    },
    zindex = 500,
    enter = false,
    focusable = false,
  }
  local help_opts = vim.deepcopy(popup_opts)
  help_opts.border.text.top = "Help"
  local help_menu = Popup(help_opts)
  local helps = {
      Line({Text("Focus next", "Title")}),
      Line({Text("  "..menu.join_keys(keys.focus_next), "SpecialKey")}),
      Line({Text("Focus previous", "Title")}),
      Line({Text("  "..menu.join_keys(keys.focus_prev), "SpecialKey")}),
      Line({Text("Select", "Title")}),
      Line({Text("  "..menu.join_keys(keys.submit), "SpecialKey")}),
      Line({Text("Close menu", "Title")}),
      Line({Text("  "..menu.join_keys(keys.close), "SpecialKey")}),
  }
  for i,h in ipairs(helps) do
    h:render(help_menu.bufnr, help_menu.ns_id, i)
  end

  local action_opts = vim.deepcopy(popup_opts)
  action_opts.border.text.top = "Actions"
  local action_menu = Popup(action_opts)
  local actions = {
      Line({Text("New terminal", "Title")}),
      Line({Text("  "..menu.join_keys(keys.new), "SpecialKey")}),
      Line({Text("Destroy terminal", "Title")}),
      Line({Text("  "..menu.join_keys(keys.destroy), "SpecialKey")}),
      Line({Text("Change terminal style", "Title")}),
      Line({Text("  "..menu.join_keys(keys.change_style), "SpecialKey")}),
      Line({Text("Change terminal layout", "Title")}),
      Line({Text("  "..menu.join_keys(keys.change_layout), "SpecialKey")}),
      Line({Text("Toggle terminal visibility", "Title")}),
      Line({Text("  "..menu.join_keys(keys.toggle), "SpecialKey")}),
      Line({Text("Change default terminal type", "Title")}),
      Line({Text("  "..menu.join_keys(keys.change_default_type), "SpecialKey")}),
  }
  for i,a in ipairs(actions) do
    a:render(action_menu.bufnr, action_menu.ns_id, i)
  end

  local hint_opts = vim.deepcopy(popup_opts)
  hint_opts.border.text.top = "Hints"
  local hint_menu = Popup(hint_opts)
  local hints = {
    Line({Text("Default type: "..Nuiterm.config.type, "Title")}),
    Line({Text(" * = displayed terminal", "SpecialKey")})
  }
  for i,h in ipairs(hints) do
    h:render(hint_menu.bufnr, hint_menu.ns_id, i)
  end

  return help_menu, action_menu, hint_menu
end

function menu.show_menu(on_submit)
  vim.schedule(function() vim.cmd[[stopinsert]] end)
  vim.cmd[[redraw]]
  on_submit = on_submit or menu.toggle_submit
  local lines = {}
  menu.add_editor_terms(lines)
  menu.add_tab_terms(lines)
  menu.add_window_terms(lines)
  menu.add_buffer_terms(lines)
  local keys = vim.deepcopy(Nuiterm.config.ui.menu_keys)
  local terminal_menu = menu.create_menu(lines,keys,on_submit)
  local help_menu, action_menu, hint_menu = menu.create_help(keys)
  local menu_layout = Layout(Nuiterm.config.ui.menu_opts,
      Layout.Box({
        Layout.Box(terminal_menu, {size = "70%"}),
        Layout.Box({
          Layout.Box(help_menu, {size = {height = 10}}),
          Layout.Box(action_menu, {size = {height = 14}}),
          Layout.Box(hint_menu, {size = {height = 4}}),
      }, {dir="col", size = {width = 30}})
    }, {dir="row", size = "70%"})
  )
  menu_layout:mount()
  menu.set_autocmds(terminal_menu, menu_layout)
  menu.set_mappings(terminal_menu, keys)
  menu.terminal_menu = terminal_menu
  menu.menu_layout = menu_layout
end

function menu.set_mappings(terminal_menu, keys)
  for _,k in ipairs(keys.new) do
    terminal_menu:map("n", k, menu.new_terminal, {noremap=true})
  end
  for _,k in ipairs(keys.destroy) do
    terminal_menu:map("n", k, menu.destroy_terminal, {noremap=true})
  end
  for _,k in ipairs(keys.change_style) do
    terminal_menu:map("n", k, menu.change_style, {noremap=true})
  end
  for _,k in ipairs(keys.change_layout) do
    terminal_menu:map("n", k, menu.change_layout, {noremap=true})
  end
  for _,k in ipairs(keys.toggle) do
    terminal_menu:map("n", k, menu.toggle_terminal, {noremap=true})
  end
  for _,k in ipairs(keys.change_default_type) do
    terminal_menu:map("n", k, menu.change_default_type, {noremap=true})
  end
end

function menu.set_autocmds(terminal_menu,menu_layout)
  -- Close terminal
  terminal_menu:on({event.BufLeave}, function()
    menu_layout:unmount()
  end, {})
end

function menu.join_keys(keys)
  if keys then
    return table.concat(keys, ", ")
  else
    return ""
  end
end

function menu.toggle_submit(item)
  if item then
    local term,type,type_id = utils.find_by_type_and_num(item.type,item.type_id)
    local was_shown = term:isshown()
    Nuiterm.toggle(type,type_id)
    if was_shown then menu.show_menu() end
  end
end

function menu.send_submit(item,cmd,setup_cmd)
  if item then
    local _,type,type_id = utils.find_by_type_and_num(item.type,item.type_id)
    Nuiterm.send(cmd, type, type_id, setup_cmd)
  end
end

function menu.bind_submit(item, buf)
  if item then
    local _,type,type_id = utils.find_by_type_and_num(item.type,item.type_id)
    Nuiterm.bind_buf_to_terminal(type, type_id, buf)
  end
end

-------------------------------------------------------------------------------
-- Populating menu
-------------------------------------------------------------------------------
function menu.resize_bufname(buf_name)
    local buf_parts = {}
    for part in buf_name:gmatch("([^/]+)/?") do table.insert(buf_parts, part) end
    local num_parts = #buf_parts
    buf_parts = {unpack(buf_parts, num_parts-Nuiterm.config.menu_buf_depth, num_parts)}
    return table.concat(buf_parts, "/")
end

function menu.in_lines(lines, item)
  local in_lines = false
  for _,line in ipairs(lines) do
    if line.text == item.text then
      in_lines = true
    end
  end
  return in_lines
end

function menu.add_editor_terms(lines,remove_header)
  local editor_terms = utils.get_mounted("editor")
  if utils.dict_length(editor_terms) > 0 then
    if not remove_header then
      if #lines ~= 0 then
        lines[#lines+1] = Menu.separator("", {char=""})
      end
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
      if menu.in_lines(lines, menu_item) == false then
        lines[#lines+1] = menu_item
      end
    end
  end
end

function menu.add_tab_terms(lines,remove_header)
  local tab_terms = utils.get_mounted("tab")
  if utils.dict_length(tab_terms) > 0 then
    if not remove_header then
      if #lines ~= 0 then
        lines[#lines+1] = Menu.separator("", {char=""})
      end
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
      if menu.in_lines(lines, menu_item) == false then
        lines[#lines+1] = menu_item
      end
    end
  end
end

function menu.add_window_terms(lines,remove_header)
  local window_terms = utils.get_mounted("window")
  if utils.dict_length(window_terms) > 0 then
    if not remove_header then
      if #lines ~= 0 then
        lines[#lines+1] = Menu.separator("", {char=""})
      end
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
      if menu.in_lines(lines, menu_item) == false then
        lines[#lines+1] = menu_item
      end
    end
  end
end

function menu.add_buffer_terms(lines,remove_header)
  local buffer_terms = utils.get_mounted("buffer")
  if utils.dict_length(buffer_terms) > 0 then
    if not remove_header then
      if #lines ~= 0 then
        lines[#lines+1] = Menu.separator("", {char=""})
      end
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
      if menu.in_lines(lines, menu_item) == false then
        lines[#lines+1] = menu_item
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Menu commands
-------------------------------------------------------------------------------
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
              menu.menu_layout:unmount()
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
  local tree = menu.terminal_menu.tree
  local node = tree:get_node()
  if node then
    local term,_,_ = utils.find_by_type_and_num(node.type,node.type_id)
    if Nuiterm.config.menu_confirm_destroy then
      vim.ui.input({prompt = "Destroy terminal? (y/n/[s]how) "}, function(input)
        if input == "y" then
          term:unmount()
          tree:remove_node(node._id)
          tree:render()
        elseif input == "" or input == "s" or input == "show" then
          menu.terminal_menu:unmount()
          term:show(Nuiterm.config.focus_on_open)
        end
      end)
    else
      term:unmount()
      tree:remove_node(node._id)
      tree:render()
    end
  end
end

function menu.toggle_terminal()
  local tree = menu.terminal_menu.tree
  local node = tree:get_node()
  if node then
    local _,type,type_id = utils.find_by_type_and_num(node.type,node.type_id)
    menu.terminal_menu:unmount()
    Nuiterm.toggle(type,type_id)
    menu.show_menu()
  end
end

function menu.change_style()
  local tree = menu.terminal_menu.tree
  local node = tree:get_node()
  if node then
    local shown_info = utils.find_shown()
    if shown_info then
      local term = Nuiterm.terminals[shown_info[1]][shown_info[2]]
      menu.terminal_menu:unmount()
      Nuiterm.hide_all_terms()
      Nuiterm.change_style(nil, node.type, node.type_id)
      term:show()
      menu.show_menu()
    else
      Nuiterm.change_style(nil, node.type, node.type_id)
    end
  end
end

function menu.change_layout()
  local tree = menu.terminal_menu.tree
  local node = tree:get_node()
  if node then
    local shown_info = utils.find_shown()
    if shown_info then
      local term = Nuiterm.terminals[shown_info[1]][shown_info[2]]
      menu.terminal_menu:unmount()
      Nuiterm.hide_all_terms()
      Nuiterm.change_layout(nil, node.type, node.type_id)
      term:show()
      menu.show_menu()
    else
      Nuiterm.change_layout(nil, node.type, node.type_id)
    end
  end
end

function menu.change_default_type()
  Nuiterm.change_default_type()
  menu.terminal_menu:unmount()
  menu.show_menu()
end

return menu
