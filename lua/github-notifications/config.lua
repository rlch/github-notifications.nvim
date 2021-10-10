local secrets = require("github-notifications.secrets")

local M = {}

local defaults = {
	debounce_duration = 60,
	username = secrets.username,
	token = secrets.token,
	icon = "",
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
	if not user_config or type(user_config) ~= "table" then
		return config
	end
	config = setmetatable(user_config, mt)
	return config
end

return M
