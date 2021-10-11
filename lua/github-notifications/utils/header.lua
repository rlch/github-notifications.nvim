local M = {}

-- If-Modified-Since: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
M.last_modified = function(seconds_since_epoch)
	if seconds_since_epoch == nil then
		seconds_since_epoch = os.time()
	end
  -- Here, ! enforces GMT
	return os.date("!%a, %d %b %Y %H:%M:%S GMT", seconds_since_epoch)
end

return M
