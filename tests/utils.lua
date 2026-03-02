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

--- Check if a pattern exists in a terminal's buffer content.
--- Retries with short sleeps to handle async terminal output.
--- @param child table MiniTest child neovim instance
--- @param pattern string text to search for
--- @param type string|nil terminal type (defaults to finding shown terminal)
--- @param type_id string|nil terminal id
--- @return boolean
function M.is_in_term_buf(child, pattern, type, type_id)
  local find_cmd
  if type and type_id then
    find_cmd = string.format(
      "Nuiterm.terminals['%s']['%s']", type, type_id)
  else
    find_cmd = [[
      (function()
        for _,group in pairs(Nuiterm.terminals) do
          for _,term in pairs(group) do
            if term:isshown() then return term end
          end
        end
      end)()
    ]]
  end
  local escaped = pattern:gsub("'", "\\'")
  local check = string.format([[
    local term = %s
    if not term or not term.bufnr then _G._term_buf_check = false; return end
    local lines = vim.api.nvim_buf_get_lines(term.bufnr, 0, -1, false)
    local text = table.concat(lines, "\n")
    _G._term_buf_check = text:find('%s', 1, true) ~= nil
  ]], find_cmd, escaped)

  -- Retry up to 10 times with 100ms waits for async terminal output
  for _ = 1, 10 do
    child.lua(check)
    if child.lua_get('_G._term_buf_check') then return true end
    child.loop.sleep(100)
  end
  return false
end

return M