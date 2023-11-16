local utils = {}

function utils.get_type_id(type,num)
  if num and tonumber(num) >= 0 then
    return tostring(num)
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
    return tostring(type_id)
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

function utils.find_mounted()
  local all_mounted = {}
  for type,terminals in pairs(Nuiterm.terminals) do
    for id,term in pairs(terminals) do
      if term.ui.object._.mounted then
        table.insert(all_mounted, {type,id})
      end
    end
  end
  if #all_mounted > 0 then
    return all_mounted
  else
    return nil
  end
end

function utils.write_quit(write, all)
  if write and vim.o.modified then
    vim.cmd[[write]]
  end
  if all then
    vim.cmd[[quitall]]
  else
    vim.cmd[[quit]]
  end
end

return utils
