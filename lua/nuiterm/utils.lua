local utils = {}

function utils.get_type_id(type,num)
  if num then
    return num
  else
    local type_id = 1
    if type == "editor" then
      type_id = num or utils.table_length(Nuiterms[type])+1
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

return utils
