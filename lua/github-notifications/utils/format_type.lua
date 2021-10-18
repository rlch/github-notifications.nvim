return function(type)
  if type == 'Issue' then
    return ''
  elseif type == 'PullRequest' then
    return ''
  elseif type == 'CheckSuite' then
    return ''
  end
  return type
end
