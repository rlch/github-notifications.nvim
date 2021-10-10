local a = require 'plenary.async'
local curl = require 'plenary.curl'
local config = require 'github-notifications.config'
local header = require 'github-notifications.utils.header'

local M = { notification_count = 0, notifications = {}, ignore = {} }
local state = nil

-- Setup user configuration
M.setup = function(options)
	options = config.set(options)
	state = {
		last_refresh = nil,
		last_response = nil,
		debounce_duration = options.debounce_duration,
	}
end

-- Calls fn if enough time has passed s.t. the user is able to make a new request.
local debounce = function(fn)
	return function(...)
		if not state then
			return
		end
		if not state.last_refresh then
			return fn(...)
		end

		local debounce_ok_at = state.last_refresh + state.debounce_duration
		if debounce_ok_at < os.time() then
			fn(...)
		end
	end
end

-- Makes a new get request to the notifications API, refreshing the state variables.
M.refresh = function()
	debounce(function()
		local wrapped_request = a.wrap(function(callback)
			local previous_last_refresh = state.last_refresh
			state.last_refresh = os.time()

			state.last_response = curl.get('https://api.github.com/notifications', {
				accept = 'application/json',
				auth = config.get 'username' .. ':' .. config.get 'token',
				headers = {
					if_modified_since = previous_last_refresh and header.last_modified(previous_last_refresh) or nil,
				},
			})
			callback()
		end, 1)

		local async_void = a.void(function(async_request)
			async_request()

			local res = state.last_response
			local status = res.status

			if status == 200 then
				local json = vim.fn.json_decode(res.body)

				for k, _ in pairs(M.notifications) do
					M.notifications[k] = nil
				end

				local count = 0
				for _, v in pairs(json) do
					if M.ignore[v] then
					else
						table.insert(M.notifications, v)
						if v ~= nil then
							count = count + 1
						end
					end
				end
				M.notification_count = count

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
		end)
		async_void(wrapped_request)
	end)()
end

M.statusline_notification_count = function()
	if state ~= nil then
		M.refresh()
	end
	return config.get 'icon' .. ' ' .. tostring(M.notification_count)
end

return M
