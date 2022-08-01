local a = require 'plenary.async'
local Job = require 'plenary.job'
local curl = require 'plenary.curl'
local config = require 'github-notifications.config'
local generate_last_modified = require('github-notifications.utils.date').last_modified

local M = { notifications = {}, ignore = {}, gh_status = nil }
local state = { last_refresh = nil, debounce_duration = config.get 'debounce_duration' }

-- Setup user configuration
M.setup = function(options)
  options = config.set(options)
end

-- Calls fn if enough time has passed s.t. the user is able to make a new request.
local debounce = function(fn)
  return function(...)
    if not state then
      return
    elseif not state.last_refresh then
      return fn(...)
    end

    local debounce_ok_at = state.last_refresh + state.debounce_duration
    if debounce_ok_at < os.time() then
      fn(...)
    end
  end
end

local set_notifications = function(res)
  local status = res.status

  if status == 200 then
    local json = vim.fn.json_decode(res.body)

    if next(M.notifications) ~= nil then
      for _, v in pairs(json) do
        if not M.notifications[v.id] then
          config.get('hooks').on_notification(v)
        end
      end
    end

    for k, _ in pairs(M.notifications) do
      M.notifications[k] = nil
    end

    for _, v in pairs(json) do
      if M.ignore[v.id] then
      elseif v ~= nil then
        M.notifications[v.id] = v
      end
    end

    -- Reduce the debounce duration if necessary
    for _, v in pairs(res.headers) do
      local interval_match = v:match 'x%-poll%-interval: (%d+)'
      if interval_match then
        local interval = tonumber(interval_match)
        local dd = state.debounce_duration

        -- In the latter case, we should revert to the user's config
        state.debounce_duration = interval > dd and interval or config.get 'debounce_duration'
      end
    end
  elseif status == 401 then
    vim.notify('Unauthorized request. Ensure username + token are valid', vim.log.levels.ERROR)
  elseif status == 403 then
    vim.notify('Forbidden. Ensure username + token are valid', vim.log.levels.ERROR)
  elseif status == 422 then
    vim.notify('Validation failure', vim.log.levels.ERROR)
  end
end

-- Makes a new get request to the notifications API, refreshing the state variables.
M.refresh = function()
  debounce(function()
    a.run(
      a.wrap(function(update_callback)
        local previous_last_refresh = state.last_refresh
        local if_modified_since = (previous_last_refresh and config.get 'cache')
            and generate_last_modified(previous_last_refresh)
          or nil
        state.last_refresh = os.time()

        local gh_status = M.gh_status or vim.api.nvim_eval [[executable('gh')]]
        M.gh_status = gh_status

        if gh_status == 1 then
          local args = if_modified_since and { '-H', '"If-Modified-Since: ' .. if_modified_since .. '"' } or {}
          for _, v in pairs { 'api', 'notifications' } do
            table.insert(args, v)
          end

          local job = Job:new { command = 'gh', args = args }
          job:after_success(vim.schedule_wrap(function(j)
            local notifications = j:result()
            -- TODO: handle other statuses
            update_callback {
              status = 200,
              body = notifications,
              headers = {},
            }
          end))
          job:start()
        else
          local res = curl.get('https://api.github.com/notifications', {
            accept = 'application/json',
            auth = config.get 'username' .. ':' .. config.get 'token',
            headers = { if_modified_since = if_modified_since },
          })
          update_callback(res)
        end
      end, 1),
      set_notifications
    )
  end)()
end

local notification_count = function()
  local count = 0
  for _, v in pairs(M.notifications) do
    count = count + (v.unread and 1 or 0)
  end
  return count
end

M.statusline_notification_count = function()
  if state ~= nil then
    M.refresh()
  end

  local count = notification_count()

  if config.get 'hide_statusline_on_all_read' and count == 0 then
    return ''
  end
  return config.get 'icon' .. ' ' .. tostring(count)
end

M.statusline_notifications = function()
  if state ~= nil then
    M.refresh()
  end

  return {
    icon = config.get 'icon',
    count = notification_count(),
  }
end

return M
