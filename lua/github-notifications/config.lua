local M = {}

local defaults = {
  debounce_duration = 60, -- Minimum time until next refresh
  username = nil, -- GitHub username
  token = nil, -- Your personal access token with `notifications` scope
  icon = '', -- Icon to be shown in statusline
  mappings = {
    mark_read = '<CR>',
    -- open_in_browser = 'o', (WIP)
    -- hide = 'd', (WIP)
  },
}
local mt = { __index = defaults }
local config = setmetatable({}, mt)

M.get = function(key)
  if key then
    return config[key]
  end
  return config
end

M.set = function(user_config)
  if not user_config or type(user_config) ~= 'table' then
    return config
  end
  for key, _ in pairs(user_config) do
    if user_config[key] and type(user_config[key]) == 'table' then
      setmetatable(user_config[key], { __index = defaults[key] })
    end
  end
  config = setmetatable(user_config, mt)
  return config
end

return M
