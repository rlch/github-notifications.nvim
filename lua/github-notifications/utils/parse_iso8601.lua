-- Parse an ISO8601 string to a seconds since epoch timestamp. Assumes UTC.
return function(date)
  local pattern = '(%d+)%-(%d+)%-(%d+)%a(%d+)%:(%d+)%:([%d%.]+)([Z%+%-])(%d?%d?)%:?(%d?%d?)'
  local year, month, day, hour, minute, seconds = date:match(pattern)
  local timestamp = os.time { year = year, month = month, day = day, hour = hour, min = minute, sec = seconds }
  return timestamp
end
