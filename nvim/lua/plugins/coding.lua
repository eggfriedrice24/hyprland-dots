return {
	-- copilot (disabled by default, toggle with <leader>cp)
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		keys = {
			{
				"<leader>cp",
				function()
					local ok, _ = pcall(require, "copilot")
					if not ok then
						vim.cmd("Copilot")
					end
					local suggestion = require("copilot.suggestion")
					suggestion.toggle_auto_trigger()
					local enabled = vim.b.copilot_suggestion_auto_trigger
					vim.notify("Copilot " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
				end,
				desc = "Toggle Copilot",
			},
		},
		opts = {
			suggestion = {
				auto_trigger = false,
				keymap = {
					accept = "<C-Right>",
					accept_word = "<M-l>",
					accept_line = "<M-S-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-Left>",
				},
			},
			filetypes = {
				markdown = true,
				help = true,
			},
		},
	},
}
