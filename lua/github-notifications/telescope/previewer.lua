local previewers = require 'telescope.previewers'
local ts_utils = require 'telescope.utils'
local defaulter = ts_utils.make_default_callable
local format_type = require 'github-notifications.utils.format_type'
local time_ago = require 'github-notifications.utils.time_ago'
local iso8601_to_unix = require('github-notifications.utils.date').iso8601_to_unix

local a = vim.api

local coalesce = function(obj, into)
  return (obj and obj ~= vim.NIL) and obj or into
end

--[[ local not_nil = function(t)
  local new_t = {}
  for _, v in ipairs(t) do
    if v ~= nil then
      table.insert(new_t, v)
    end
  end
  return new_t
end ]]

return defaulter(function(_)
  return previewers.new_buffer_previewer {
    get_buffer_by_name = function(_, entry)
      return entry.id
    end,
    define_preview = function(self, entry)
      local bufnr = self.state.bufnr

      -- local url = coalesce(entry.value.subject.url, nil)

      local lines = {
        '# ' .. entry.value.subject.title,
        '> ' .. format_type(entry.value.subject.type) .. ' ' .. entry.value.subject.type,
        '> Updated: ' .. time_ago.format(iso8601_to_unix(entry.value.updated_at)),
        '',
        -- url and ('- 爵' .. url) or nil,
        '-  ' .. entry.value.repository.full_name,
        '- Read: ' .. (entry.value.unread and '' or ''),
        '- Reason: ' .. entry.value.reason,
      }

      a.nvim_buf_set_lines(bufnr, 0, #lines + 1, false, lines)
      a.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
    end,
  }
end)
