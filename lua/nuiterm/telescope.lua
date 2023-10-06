local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local menu = require("nuiterm.menu")
local nuiterm = require("nuiterm")

local terminal_finder = {}

terminal_finder.picker = function(opts)
	opts = opts or {}
	local nuiterm_finder = function()
		local terminals = {}
    menu.add_editor_terms(terminals,true)
    menu.add_tab_terms(terminals,true)
    menu.add_window_terms(terminals,true)
    menu.add_buffer_terms(terminals,true)

		local nuiterm_maker = function(entry)
      local item = {type = entry.type, type_id = entry.type_id}
			return {value = item, display = entry.text, ordinal = entry.text}
		end

		return finders.new_table({ results = terminals, entry_maker = nuiterm_maker })
	end
  local nuiterm_previewer = previewers.new_buffer_previewer({
    title = "Terminal contents",
    define_preview = function(self, entry, _)
      local height = vim.api.nvim_win_get_height(self.state.winid)
      local term_bufnr = Nuiterm.terminals[entry.value.type][entry.value.type_id].bufnr
      local term_lines = vim.api.nvim_buf_get_lines(term_bufnr, -2*height, -1, false)
      -- Remove any repeating empty rows
      local new_term_lines = {}
      local was_empty = false
      for _,l in pairs(term_lines) do
        if l == "" then
          local is_empty = true
          if is_empty and not was_empty then
            table.insert(new_term_lines, l)
          end
          was_empty = true
        else
          table.insert(new_term_lines, l)
          was_empty = false
        end
      end
      new_term_lines = {unpack(new_term_lines, math.max(#new_term_lines-height+1,1))}
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, new_term_lines)
    end
  })

	pickers.new(opts, {
		prompt_title = "Select a terminal",
		results_title = "Nuiterms",
		finder = nuiterm_finder(),
		sorter = conf.generic_sorter(opts),
    previewer = nuiterm_previewer,

		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()

				local item = selection['value']

        nuiterm.toggle(item.type,item.type_id)
			end)
			return true
		end,
	}):find()
end

return terminal_finder
