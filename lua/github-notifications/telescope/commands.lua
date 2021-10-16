local a = require 'plenary.async'
local Job = require 'plenary.job'
local curl = require 'plenary.curl'

local ghn = require 'github-notifications'
local config = require 'github-notifications.config'

local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local M = {}

M.read_notification = function(notification, bufnr)
  local id = notification.ordinal

  a.run(
    a.wrap(function(update_state_callback)
      if ghn.gh_status == 1 then
        local job = Job:new {
          command = 'gh',
          args = { 'api', '-X', 'PATCH', '/notifications/threads/' .. tostring(id) },
        }

        --[[ job:after_success(vim.schedule_wrap(function(j)
          update_state_callback()
        end)) ]]

        update_state_callback()

        job:after_failure(vim.schedule_wrap(function(j)
          vim.notify(j:stderr_result(), vim.log.levels.ERROR)
        end))

        job:start()
      else
        curl.patch('https://api.github.com/notifications/threads/' .. tostring(id), {
          auth = config.get 'username' .. ':' .. config.get 'token',
        })
        update_state_callback()
      end
    end, 1),
    function()
      local done = false
      for k, v in pairs(ghn.notifications) do
        if not done and k == notification.ordinal then
          done = true
          ghn.notifications[k].unread = false

          if config.get 'hide_entry_on_read' then
            ghn.ignore[v.id] = true
          end

          local picker = action_state.get_current_picker(bufnr)
          picker:move_selection(0) -- refreshes current entry
          picker:move_selection(1) -- move to next entry
        end
      end
    end
  )
end

M.read_all_notifications = function(_, bufnr)
  a.run(
    a.wrap(function(update_state_callback)
      if ghn.gh_status == 1 then
        local job = Job:new {
          command = 'gh',
          args = { 'api', '-X', 'PUT', '/notifications' },
        }

        job:after_success(vim.schedule_wrap(function()
          update_state_callback()
        end))

        job:start()
        update_state_callback()
      else
        curl.put('https://api.github.com/notifications', {
          auth = config.get 'username' .. ':' .. config.get 'token',
        })
        update_state_callback()
      end
    end, 1),
    function()
      for k, _ in pairs(ghn.notifications) do
        ghn.notifications[k].unread = false
      end
      actions.close(bufnr)
    end
  )
end

M.hide = function(notification, bufnr)
  for k, _ in pairs(ghn.notifications) do
    if k == notification.ordinal then
      ghn.notifications[k] = nil
      ghn.ignore[k] = true

      local picker = action_state.get_current_picker(bufnr)
      picker:delete_selection(function() end)
    end
  end
end

-- TODO: link to notifications follow-up URL
-- Credit to @nanotee
M.open_in_browser = function(notification)
  local url = notification.value.subject.url
  if vim.fn.has 'mac' == 1 then
    vim.cmd('call jobstart(["open", expand("' .. url .. '")], {"detach": v:true})')
  elseif vim.fn.has 'unix' == 1 then
    vim.cmd('call jobstart(["xdg-open", expand("' .. url .. '")], {"detach": v:true})')
  else
    vim.notify('gx not supported on this OS', vim.log.levels.ERROR)
  end
end

return M
