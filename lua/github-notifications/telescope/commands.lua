local a = require 'plenary.async'
local Job = require 'plenary.job'
local curl = require 'plenary.curl'

local ghn = require 'github-notifications'
local config = require 'github-notifications.config'

local M = {}

M.read_notification = function(notification)
  local id = notification.ordinal

  a.run(
    a.wrap(function(update_state_callback)
      if ghn.gh_status == 1 then
        local job = Job:new {
          command = 'gh',
          args = { 'api', 'notifications/threads/' .. tostring(id) },
        }

        job:after_success(vim.schedule_wrap(function()
          update_state_callback()
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
      for k, v in pairs(ghn.notifications) do
        if v == notification.value then
          ghn.notifications[k].unread = false
          -- Hide the next time the popup is opened (WIP)
          -- ghn.ignore[v] = true
        end
      end
    end
  )
end

-- TODO: fix
M.hide = function(notification)
  for k, v in pairs(ghn.notifications) do
    if v == notification.value then
      ghn.notifications[k] = nil
      ghn.ignore[v] = true
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
