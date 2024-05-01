local user_commands = {}

function user_commands.create_commands()
  vim.api.nvim_create_user_command("Nuiterm", function(input)
    local keys = {"type", "num", "cmd"}
    local fargs = user_commands.parse(input.fargs, keys)
    Nuiterm.toggle(fargs.type, fargs.num, fargs.cmd)
  end, {nargs="*"})

  vim.api.nvim_create_user_command("NuitermSend", function(input)
    local keys = {"cmd", "type", "num", "setup_cmd"}
    local fargs = user_commands.parse(input.fargs, keys)
    if fargs.cmd then
      -- Specified command
      Nuiterm.send_select(fargs.cmd, fargs.type, fargs.num, fargs.setup_cmd)
    else
      keys = {"type", "num", "setup_cmd"}
      fargs = user_commands.parse(input.fargs, keys)
      if input.count > 0 then
        if input.line1 ~= input.line2 then
          -- Specified multiple lines
          Nuiterm.send_lines(input.line1, input.line2, fargs.type, fargs.num, fargs.setup_cmd)
        else
          if input.range > 1 then
            -- Specified visual selection
            Nuiterm.send_visual(fargs.type, fargs.num, fargs.setup_cmd)
          else
            -- Specified single line
            Nuiterm.send_lines(input.line1, input.line2, fargs.type, fargs.num, fargs.setup_cmd)
          end
        end
      else
        -- No specified line or command -> send this line
        Nuiterm.send_line(fargs.type, fargs.num, fargs.setup_cmd)
      end
    end
  end, {nargs="*", range=true})

  vim.api.nvim_create_user_command("NuitermChangeStyle", function(input)
    local keys = {"style", "type", "num"}
    local fargs = user_commands.parse(input.fargs, keys)
    Nuiterm.change_style(fargs.style, fargs.type, fargs.num)
  end, {nargs="*"})

  vim.api.nvim_create_user_command("NuitermChangeLayout", function(input)
    local keys = {"type", "num"}
    local fargs = user_commands.parse(input.fargs, keys)
    Nuiterm.change_layout(nil, fargs.type, fargs.num)
  end, {nargs="*"})

  vim.api.nvim_create_user_command("NuitermBindBuf", function(input)
    local keys = {"type", "num"}
    local fargs = user_commands.parse(input.fargs, keys)
    Nuiterm.bind_buf_to_terminal(fargs.type, fargs.num)
  end, {nargs="*"})

  vim.api.nvim_create_user_command("NuitermHideAll",
    Nuiterm.hide_all_terms, {nargs=0})

  vim.api.nvim_create_user_command("NuitermMenu",
    Nuiterm.toggle_menu, {nargs=0})

  vim.api.nvim_create_user_command("NuitermChangeDefaultType", function(input)
    local keys = {"type"}
    local fargs = user_commands.parse(input.fargs, keys)
    Nuiterm.change_default_type(fargs.type)
  end, {nargs="*"})
end

function user_commands.parse(fargs, keys)
  local parsed = {}
  for i,arg in ipairs(fargs) do
    local key = string.match(arg, "(.+)=")
    local value = string.match(arg, "=(.+)")
    if key == nil then
      key = keys[i]
      value = string.match(arg, "(.+)")
    end
    parsed[key] = value
  end
  return parsed
end

return user_commands
