local curl = require("plenary.curl")
local config = require("github-notifications.config")
local header = require("github-notifications.utils.header")

local M = {
	notification_count = 0,
	statusline_notification_count = function() end,
}

local state = {
	last_refresh = nil,
	poll = nil,
}

-- Setup user configuration
M.setup = function(options)
	options = config.set(options)
	print(options.debounce_duration)
	state.debounce_duration = options.debounce_duration
	M.refresh()
end

-- Returns whether enough time has passed s.t. the user is able to make a new request.
local debounce = function()
	if not state.last_refresh then
		return true
	end

	print("dif: " .. tostring(state.last_refresh + state.debounce_duration - os.time()))
	print("last modified:" .. tostring(state.last_refresh and header.last_modified(state.last_refresh) or nil))
	local debounce_ok_at = state.last_refresh + state.debounce_duration
	return debounce_ok_at < os.time()
end

-- Makes a new get request to the notifications API, refreshing the state variables.
M.refresh = function()
	if not debounce() then
		print("Not enough time has passed!")
		return
	end

	local res = curl.get("https://api.github.com/notifications", {
		accept = "application/json",
		auth = config.get("username") .. ":" .. config.get("token"),
		headers = {
			if_modified_since = state.last_refresh and header.last_modified(state.last_refresh) or nil,
		},
	})

	local status = res.status
	print(status)

	if status == 200 then
		local json = vim.fn.json_decode(res.body)

		local count = 0
		for _, v in pairs(json) do
			if v ~= nil then
				print(v.subject.title)
				count = count + 1
			end
		end
		M.notification_count = count
		M.statusline_notification_count = function()
			return " " .. tostring(count)
		end

		print("status: " .. res.status)
		-- print("headers: " .. res.headers)
		print("count: " .. count)
		print(M.statusline_notification_count)

		-- Reduce the debounce duration if necessary
		for _, v in pairs(res.headers) do
			local interval_match = v:match("x%-poll%-interval: (%d+)")
			if interval_match then
				local interval = tonumber(interval_match)
				local dd = state.debounce_duration
				print("interval: " .. tostring(interval) .. " dd: " .. tostring(dd))

				-- In the latter case, we should revert to the user's config
				state.debounce_duration = interval > dd and interval or config.get("debounce_duration")
			end
		end

		state.last_refresh = os.time()
	elseif status == 304 then
		print("Not modified!")
		return
	elseif status == 401 then
		print("Unauthorized")
	elseif status == 403 then
		print("Forbidden")
	elseif status == 422 then
		print("Validation failure")
	end
end

return M
