local Menu = require("nui.menu")
local nuiterm = require("nuiterm")
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

function menu.show_terminal_menu()
  local lines = {}
  if utils.table_length(Nuiterms["editor"]) > 0 then
    lines[#lines+1] = Menu.separator("Editor")
    for _,t in pairs(Nuiterms["editor"]) do
      local menu_item = Menu.item(
        tostring(t.type_id),{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if utils.table_length(Nuiterms["tab"]) > 0 then
    lines[#lines+1] = Menu.separator("Tab")
    for _,t in pairs(Nuiterms["tab"]) do
      local buf_names = ""
      for _,win in pairs(vim.api.nvim_tabpage_list_wins(t.type_id)) do
        buf_names = buf_names.." "..vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      end
      local display = "Tab: "..t.type_id.." -- Buffers in tab: "..buf_names
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if utils.table_length(Nuiterms["window"]) > 0 then
    lines[#lines+1] = Menu.separator("Window")
    for _,t in pairs(Nuiterms["window"]) do
      local buf_name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(t.type_id))
      local display = "Window: "..t.type_id.." -- Buffer in window: "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  if utils.table_length(Nuiterms["buffer"]) > 0 then
    lines[#lines+1] = Menu.separator("Buffer")
    for _,t in pairs(Nuiterms["buffer"]) do
      local buf_name = vim.api.nvim_buf_get_name(t.type_id)
      local display = "Buffer: "..t.type_id.." -- Name: "..buf_name
      local menu_item = Menu.item(
        display,{type=t.type,type_id=t.type_id}
      )
      lines[#lines+1] = menu_item
    end
  end
  nuiterm.terminal_menu = Menu(menu.menu_options, {
    lines = lines,
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
    on_submit = function(item)
      nuiterm.toggle(item.type,item.type_id)
    end,
  })
  nuiterm.terminal_menu:mount()
  nuiterm.menu_shown = true
end

return menu
