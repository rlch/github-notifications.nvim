local ghn = require 'github-notifications'
local config = require 'github-notifications.config'
local previewer = require 'github-notifications.telescope.previewer'
local format_type = require 'github-notifications.utils.format_type'
local commands = require 'github-notifications.telescope.commands'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local themes = require 'telescope.themes'
local sorters = require 'telescope.sorters'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'

local M = {}

local execute_command = function(slug)
	local cmd
	if slug == 'mark_read' then
		cmd = commands.read_notification
	elseif slug == 'open_in_browser' then
		cmd = commands.open_in_browser
	elseif slug == 'hide' then
		cmd = commands.hide
	end

	return function(_)
		local selection = action_state.get_selected_entry()
		cmd(selection)
	end
end

local entry_maker = function()
	local make_display = function(en)
		local displayer = entry_display.create {
			separator = ' · ',
			items = {
				{ width = 1 },
				{ remaining = true },
			},
		}

		return displayer {
			{ format_type(en.subject.type), 'Type' },
			{ tostring(en.subject.title), 'Comment' },
		}
	end

	return function(entry)
		return {
			ordinal = entry.id,
			label = entry.subject.title,
			display = make_display(entry),
			value = entry,
		}
	end
end

M.notifications = function(opts)
	ghn.refresh()

	local results = {}
	for k, v in pairs(ghn.notifications) do
		if not ghn.ignore[v] then
			results[k] = v
    else
      print(v.subject.title)
		end
	end
  print('results: ' .. tostring(#results))
	opts = opts and not vim.tbl_isempty(opts) and opts or themes.get_dropdown {}

	pickers.new(opts, {
		prompt_title = 'GitHub Notifications',
		finder = finders.new_table {
			results = results,
			entry_maker = entry_maker(),
		},
		previewer = previewer.new(opts),
		sorter = sorters.get_generic_fuzzy_sorter(),
		attach_mappings = function(_, map)
			for slug, key in pairs(config.get 'mappings') do
				map('n', key, execute_command(slug))
			end

			return true
		end,
	}):find()
end

return M