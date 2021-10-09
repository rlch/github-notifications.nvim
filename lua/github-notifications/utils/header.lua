local M = {}

M.last_modified = function(seconds_since_epoch)
	if seconds_since_epoch == nil then
		seconds_since_epoch = os.time()
	end
	return os.date("%c", seconds_since_epoch)
end

return M
