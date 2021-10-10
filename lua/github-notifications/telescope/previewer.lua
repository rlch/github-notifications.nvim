local previewers = require 'telescope.previewers'
local ts_utils = require 'telescope.utils'
local defaulter = ts_utils.make_default_callable
local format_type = require 'github-notifications.utils.format_type'
local time_ago = require 'github-notifications.utils.time_ago'
local parse_iso8601 = require 'github-notifications.utils.parse_iso8601'

local a = vim.api

return defaulter(function(_)
	return previewers.new_buffer_previewer {
		get_buffer_by_name = function(_, entry)
			return entry.id
		end,
		define_preview = function(self, entry)
			local bufnr = self.state.bufnr

			local lines = {
				'# ' .. entry.value.subject.title,
				'> ' .. format_type(entry.value.subject.type) .. ' ' .. entry.value.subject.type,
				'> Updated: ' .. time_ago.format(parse_iso8601(entry.value.updated_at)),
				'',
				'- 爵' .. entry.value.subject.url,
				'-  ' .. entry.value.repository.full_name,
				'- Read: ' .. (entry.value.unread and '' or ''),
				'- Reason: ' .. entry.value.reason,
			}

			a.nvim_buf_set_lines(bufnr, 0, #lines + 1, false, lines)
			a.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
		end,
	}
end)
