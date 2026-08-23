-- :ThemeReload - re-read the local eggfriedrice build without restarting.
-- require() caches modules, so palette edits in colors.lua are invisible
-- until the eggfriedrice.* entries are evicted; setup opts are carried
-- over across the reload.
vim.api.nvim_create_user_command("ThemeReload", function()
	local old_config = require("eggfriedrice").config
	for name in pairs(package.loaded) do
		if name == "eggfriedrice" or name:find("^eggfriedrice%.") or name == "lualine.themes.eggfriedrice" then
			package.loaded[name] = nil
		end
	end
	local theme = require("eggfriedrice")
	theme.setup(old_config)
	theme.load()

	local ok, lualine = pcall(require, "lualine")
	if ok then
		lualine.setup(lualine.get_config())
	end
	vim.notify("eggfriedrice reloaded", vim.log.levels.INFO)
end, { desc = "Reload the local eggfriedrice colorscheme build" })
