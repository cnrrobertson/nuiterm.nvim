local utils = {}

function utils.get_type_id(type,num)
  if num and num >= 0 then
    return num
  else
    local type_id = 1
    if type == "editor" then
      type_id = num or utils.find_first_unmounted(Nuiterm.terminals[type])
    elseif type == "tab" then
      type_id = vim.api.nvim_get_current_tabpage()
    elseif type == "window" then
      type_id = vim.api.nvim_get_current_win()
    elseif type == "buffer" then
      type_id = vim.api.nvim_get_current_buf()
    end
    return type_id
  end
end

function utils.table_length(t)
  local length = 0
  for _,_ in pairs(t) do
    length = length + 1
  end
  return length
end

function utils.find_first_unmounted(terminals)
  for id,term in pairs(terminals) do
    if term.ui.object._.mounted == false then
      return id
    end
  end
  return utils.table_length(terminals)+1
end

function utils.find_shown()
  for type,terminals in pairs(Nuiterm.terminals) do
    for id,term in pairs(terminals) do
      if term.ui.object.winid then
        return {type,id}
      end
    end
  end
end

return utils
