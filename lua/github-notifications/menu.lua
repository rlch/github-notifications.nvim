local ghn = require 'github-notifications'
local config = require 'github-notifications.config'
local previewer = require 'github-notifications.telescope.previewer'
local format_type = require 'github-notifications.utils.format_type'
local commands = require 'github-notifications.telescope.commands'
local iso8601_to_unix = require 'github-notifications.utils.date'.iso8601_to_unix

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local themes = require 'telescope.themes'
local sorters = require 'telescope.sorters'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'

local M = {}

local execute_command = function(prompt_bufnr, slug)
  local cmd
  if slug == 'mark_read' then
    cmd = commands.read_notification
  elseif slug == 'open_in_browser' then
    cmd = commands.open_in_browser
  elseif slug == 'hide' then
    cmd = commands.hide
  elseif slug == 'mark_all_read' then
    cmd = commands.read_all_notifications
  end

  return function(_)
    local selection = action_state.get_selected_entry()
    cmd(selection, prompt_bufnr)
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
      { en.status, 'Type' },
      { en.label, en.value.unread and 'Variable' or 'Comment' },
    }
  end

  return function(entry)
    return {
      ordinal = entry.id,
      label = tostring(entry.subject.title),
      status = format_type(entry.subject.type),
      display = make_display,
      value = entry,
    }
  end
end

M.notifications = function(opts)
  ghn.refresh()

  local results = {}
  for k, v in pairs(ghn.notifications) do
    if not ghn.ignore[k] then
      -- Telescope doesn't instantiate entries that have high in magnitude keys ?? whack
      table.insert(results, v)
    end
  end
  opts = opts and not vim.tbl_isempty(opts) and opts or themes.get_dropdown {}

  pickers.new(opts, {
    prompt_title = 'GitHub Notifications',
    finder = finders.new_table {
      results = results,
      entry_maker = entry_maker(),
    },
    previewer = previewer.new(opts),
    sorter = sorters.Sorter:new{
      scoring_function = function(_, _, _, entry)
        return -iso8601_to_unix(entry.value.updated_at)
      end
    },
    attach_mappings = function(prompt_bufnr, map)
      for slug, key in pairs(config.get 'mappings') do
        map('n', key, execute_command(prompt_bufnr, slug))
      end

      for slug, key in pairs(config.get 'prompt_mappings') do
        map('i', key, execute_command(prompt_bufnr, slug))
      end

      return true
    end,
  }):find()
end

return M
