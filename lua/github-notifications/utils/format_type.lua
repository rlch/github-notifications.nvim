return function(type)
  if type == 'Issue' then
    return ''
  elseif type == 'PullRequest' then
    return ''
  end
  return type
end
