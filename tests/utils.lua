M = {}

function M.print_screenshot(screenshot)
  vim.print("")
  for _,line in pairs(screenshot.text) do
    vim.print(table.concat(line, ""))
  end
end

function M.stack_screenshot(screenshot,s,e)
  s = s or 1
  e = e or 0
  local lines = {}
  local text = screenshot.text
  for _,line in pairs({unpack(text,s,#text-e)}) do
    table.insert(lines, table.concat(line, ""))
  end
  return table.concat(lines, "")
end

function M.find_in_screenshot(pattern, screenshot)
  local text = M.stack_screenshot(screenshot)
  local count = 0
  for _ in text:gmatch(pattern) do
    count = count + 1
  end
  return count
end

function M.is_in_screenshot(pattern, screenshot, reps)
  reps = reps or 1
  local result = M.find_in_screenshot(pattern, screenshot)
  if result == reps then
    return true
  else
    return false
  end
end

return M
