M = {}

function M.print_screenshot(screenshot)
  vim.print("")
  for _,line in pairs(screenshot.text) do
    vim.print(table.concat(line, ""))
  end
end

function M.find_in_screenshot(pattern, screenshot)
  local lines = {}
  for _,line in pairs(screenshot.text) do
    table.insert(lines, table.concat(line, ""))
  end
  local text = table.concat(lines, "")
  return string.find(text, pattern, 1, true)
end

function M.is_in_screenshot(pattern, screenshot)
  local result = M.find_in_screenshot(pattern, screenshot)
  if result then
    return true
  else
    return false
  end
end

return M
