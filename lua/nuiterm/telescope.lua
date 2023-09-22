local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
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

	pickers.new(opts, {
		prompt_title = "Select a terminal",
		results_title = "nuiterms",
		finder = nuiterm_finder(),
		sorter = conf.generic_sorter(opts),

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
