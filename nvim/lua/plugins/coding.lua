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

	-- 99 (ThePrimeagen's AI agent, uses Claude Code CLI)
	{
		"ThePrimeagen/99",
		dependencies = {
			{ "saghen/blink.compat", version = "2.*" },
		},
		config = function()
			local _99 = require("99")
			_99.setup({
				provider = _99.Providers.OpenCodeProvider,
				model = "openai/gpt-5.3-codex",
				completion = {
					source = "blink",
				},
			})

			vim.keymap.set("v", "<leader><leader>", _99.visual, { desc = "99: Visual replace" })
			vim.keymap.set("n", "<leader>9s", _99.search, { desc = "99: Search" })
			vim.keymap.set("n", "<leader>9x", _99.stop_all_requests, { desc = "99: Stop all" })

			vim.keymap.set("n", "<leader>9m", function()
				local provider = _99.get_provider()
				provider.fetch_models(function(models, err)
					if err or not models then
						vim.notify("99: " .. (err or "no models"), vim.log.levels.ERROR)
						return
					end
					vim.schedule(function()
						vim.ui.select(models, {
							prompt = "Select model:",
							format_item = function(item)
								return item == _99.get_model() and item .. " (current)" or item
							end,
						}, function(choice)
							if choice then
								_99.set_model(choice)
								vim.notify("99 model: " .. choice, vim.log.levels.INFO)
							end
						end)
					end)
				end)
			end, { desc = "99: Switch model" })

			vim.keymap.set("n", "<leader>9p", function()
				vim.ui.select({
					"ClaudeCodeProvider",
					"OpenCodeProvider",
				}, { prompt = "Select provider:" }, function(choice)
					if choice then
						_99.set_provider(_99.Providers[choice])
						vim.notify("99 provider: " .. choice, vim.log.levels.INFO)
					end
				end)
			end, { desc = "99: Switch provider" })
		end,
	},
}
