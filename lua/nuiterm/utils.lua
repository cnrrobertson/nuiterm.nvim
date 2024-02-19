local utils = {}

function utils.get_type_id(type,num)
  if num then
    if type == "editor" then
      if tonumber(num) and (tonumber(num) == -1) then
        -- Continue to get next available terminal number
      else
        return tostring(num)
      end
    else
      return tostring(num)
    end
  else
    local type_id = 1
    if type == "editor" then
      type_id = utils.find_first_unmounted(Nuiterm.terminals[type])
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

function utils.dict_length(t)
  local length = 0
  for _,_ in pairs(t) do
    length = length + 1
  end
  return length
end

function utils.find_first_unmounted(terminals)
  for id,term in pairs(terminals) do
    if term:ismounted() == false then
      return id
    end
  end
  return utils.dict_length(terminals)+1
end

function utils.find_by_bufnr(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  for group,_ in pairs(Nuiterm.terminals) do
    for id,term in pairs(Nuiterm.terminals[group]) do
      if term.bufnr == bufnr then
        return term,group,id
      end
    end
  end
end

function utils.find_shown()
  for type,terminals in pairs(Nuiterm.terminals) do
    for id,term in pairs(terminals) do
      if term:isshown() then
        return {type,id}
      end
    end
  end
end

function utils.find_by_type_and_num(type,num)
  local ft = vim.bo.filetype
  local term = nil
  if (ft == "terminal") then
    _,type,num = utils.find_by_bufnr()
  elseif type == "current" then
    local tpage = vim.api.nvim_get_current_tabpage()
    if Nuiterm.windows[tpage] and Nuiterm.windows[tpage].bufnr then
      local tbufnr = Nuiterm.windows[tpage].bufnr
      _,type,num = utils.find_by_bufnr(tbufnr)
    else
      type = Nuiterm.config.type
    end
  else
    type = type or Nuiterm.config.type
    num = utils.get_type_id(type,num)
  end
  term = Nuiterm.terminals[type][num]
  return term,type,num
end

function utils.find_mounted()
  local all_mounted = {}
  for type,terminals in pairs(Nuiterm.terminals) do
    for id,term in pairs(terminals) do
      if term:ismounted() then
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

function utils.get_mounted(type)
  local mounted_terms = {}
  for _,terminals in pairs(Nuiterm.terminals) do
    for _,term in pairs(terminals) do
      if term:ismounted() then
        if type == nil or type == term.type then
          table.insert(mounted_terms, term)
        end
      end
    end
  end
  return mounted_terms
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

function utils.rename_buffer(bufnr, name)
  vim.api.nvim_buf_set_name(bufnr,name)
  -- Renaming causes duplication of terminal buffer -> delete old buffer
  -- https://github.com/neovim/neovim/issues/20349
  local alt = vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.bufnr('#')
  end)
  if alt ~= bufnr and alt ~= -1 then
    pcall(vim.api.nvim_buf_delete, alt, {force=true})
  end
end

return utils
