local menu = require 'github-notifications.menu'

local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
	error 'This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

return telescope.register_extension {
	exports = {
		github_notifications = menu.notifications,
	},
}
