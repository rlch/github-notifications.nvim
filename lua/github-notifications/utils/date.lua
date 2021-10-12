local M = {}

-- Returns a string formatted for the Last-Modified header
M.last_modified = function(seconds_since_epoch)
  if seconds_since_epoch == nil then
    seconds_since_epoch = os.time()
  end
  -- Here, ! enforces GMT
  return os.date('!%a, %d %b %Y %H:%M:%S GMT', seconds_since_epoch)
end

local zone_diff
-- Converts a GMT date table to local time
-- https://stackoverflow.com/questions/43067106/back-and-forth-utc-dates-in-lua
local gmt_to_local = function(dt)
  dt = os.date('*t', os.time(dt)) -- normalize regardless of TZ
  if not zone_diff then
    local tmp_time = os.time()
    local d1 = os.date('*t', tmp_time)
    local d2 = os.date('!*t', tmp_time)
    d1.isdst = false
    zone_diff = os.difftime(os.time(d1), os.time(d2))
  end

  dt.sec = dt.sec + zone_diff
  return os.time(dt)
end

-- Parse an ISO8601 string to a unix timestamp. Assumes UTC.
M.iso8601_to_unix = function(date)
  -- I hate dates
  local pattern = '(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%-])(%d?%d?)%:?(%d?%d?)'
  local year, month, day, hour, minute, seconds = date:match(pattern)

  local gmt_dt = os.date(
    '!*t',
    os.time { year = year, month = month, day = day, hour = hour, min = minute, sec = seconds }
  )
  return gmt_to_local(gmt_dt)
end

return M
