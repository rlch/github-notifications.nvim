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
    'hoob3rt/lualine.nvim',
    'nvim-telescope/telescope.nvim',
  },
}
```

## Getting Started

Simply call `setup` and you're good to go:

```lua
local secrets = require 'secrets'

require('github-notifications').setup {
  username = secrets.username,
  token = secrets.token,
}
```

`token` is a personal access token with the `Notifications` scope. You can make one [here](https://github.com/settings/tokens)

**Default config**:

```lua
local defaults = {
  debounce_duration = 60, -- Minimum time until next refresh
  username = nil, -- GitHub username
  token = nil, -- Your personal access token with `notifications` scope
  icon = '', -- Icon to be shown in statusline
  mappings = {
    mark_read = '<CR>',
    -- open_in_browser = 'o', (WIP)
    -- hide = 'd', (WIP)
  },
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

### Telescope

Optionally load the extension using:

```lua
require('telescope').load_extension 'ghn'
```

So that `require('telescope').extensions.ghn.ghn()` can open the popup.

Otherwise, you can simply call:

```lua
require('github-notifications.menu').notifications()
```

I'm aware my API design is abysmal

## TODOs

- [ ] Redirect to follow-up URL (instead of API url)
- [ ] Refresh UI on state changes (i.e. when marking notifications as read)
- [ ] Add highlights to Telescope entries
- [ ] Improve Telescope preview UI instead of being lazy with markdown
- [ ] Hide notifications without Telescope shitting itself

## Contributing :ok_hand:

Please lmao
