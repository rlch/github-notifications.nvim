local M = {}

local defaults = {
  debounce_duration = 60, -- Minimum time until next refresh
  username = nil, -- GitHub username
  token = nil, -- Your personal access token with `notifications` scope
  icon = '', -- Icon to be shown in statusline
  hide_statusline_on_all_read = true,
  cache = true, -- Opt in/out of caching
  mappings = {
    mark_read = '<CR>',
    -- open_in_browser = 'o', (WIP)
    -- hide = 'd', (WIP)
  }, -- keymaps that apply on a Telescope entry level
  prompt_mappings = {
    mark_all_read = '<C-r>'
  } -- keymaps that apply on a Telescope prompt level (insert mode)
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
