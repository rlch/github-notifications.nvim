# github-notifications.nvim :bell:

A lightweight, unobstructive, yet WIP neovim plugin for viewing GitHub notifications in your statusline + Telescope popup. 
All requests are processed asynchronously, debounced and cached to ensure no delays in your UI! :rocket:

![Preview](https://imgur.com/F6CzZ8O.png)

## Installation

Use your favourite package manager:

```lua
use {
  'rlch/github-notifications.nvim',
  config = [[require('config.github-notifications')]],
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
}
```

## Getting Started

### Using `gh` CLI (recommended)

Install [the CLI](https://github.com/cli/cli) and you're off!


### Using personal access token

Call `setup` with your personal access `token` with the `Notifications` scope. You can make one [here](https://github.com/settings/tokens).

```lua
local secrets = require 'secrets'

require('github-notifications').setup {
  username = secrets.username,
  token = secrets.token,
}
```


**Default config**:

```lua
local defaults = {
  username = nil, -- GitHub username
  token = nil, -- Your personal access token with `notifications` scope
  icon = '', -- Icon to be shown in statusline
  hide_statusline_on_all_read = true,
  hide_entry_on_read = false, -- Whether to hide the Telescope entry after reading (buggy)
  debounce_duration = 60, -- Minimum time until next refresh
  cache = false, -- Opt in/out of caching
  sort_unread_first = true,
  mappings = {
    mark_read = '<CR>',
    hide = 'd', -- remove from Telescope picker, but don't mark as read
    -- open_in_browser = 'o', (WIP)
  },
  prompt_mappings = {
    mark_all_read = '<C-r>'
  } -- keymaps that apply on a Telescope prompt level (insert mode)
}
```

### Lua-based statusline 

![Statusline](https://imgur.com/4JAnmvE.png)

I've only tested this with [lualine](https://github.com/hoob3rt/lualine.nvim), but it should work with any Lua-based statusline that takes a Lua function as an argument for displaying data.

```lua
require('lualine').setup {
  ...
  sections = {
    ...
    lualine_b = { 'branch', require('github-notifications').statusline_notification_count },
    ...
  },
  ...
}
```

You can also use `statusline_notifications()` and build your own formatter:

```lua
  local ghn_formatter = function()
    local data = require('github-notifications').statusline_notifications()
    if data.count > 10 then
      return data.icon .. ' purge time'
    elseif data.count == 0 then
      return ''
    end
    return data.icon .. tostring(data.count)
  end
```


### Telescope

Optionally load the extension using:

```lua
require('telescope').load_extension 'ghn'
```

So that `require('telescope').extensions.ghn.notifications()` can open the popup.

Otherwise, you can simply call:

```lua
require('github-notifications.menu').notifications()
```

I'm aware my API design is abysmal

## TODOs

- [ ] Add support for CI status for current branch in statusline
- [ ] Redirect to follow-up URL (instead of API url)
- [x] Refresh UI on state changes (i.e. when marking notifications as read)
- [x] Add highlights to Telescope entries
- [ ] Improve Telescope preview UI instead of being lazy with markdown
- [x] Hide notifications without Telescope shitting itself

## Contributing :ok_hand:

Please lmao
