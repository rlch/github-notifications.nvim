local M = {}

local curl = require'plenary.curl'

M.setup = function()
  local res = curl.get('https://api.github.com/notifications', {
    accept = 'application/json',
    auth = USER .. ':' .. TOKEN,
  })

  local count = 0
  local json = vim.fn.json_decode(res.body)

  for _, v in pairs(json) do
    if v ~= nil then
      print(v.subject.title)
      count = count + 1
    end
  end

  print(count)
end

return M
