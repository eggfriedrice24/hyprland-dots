-- Colours come from the eggfriedrice palette (with this config's setup
-- options), never from literals. The colorscheme loads first (priority 1000).
local function palette()
	return require("eggfriedrice.colors").get(require("eggfriedrice").config)
end

return {
	-- messages, cmdline and the popupmenu
	{
		"folke/noice.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = function(_, opts)
			-- Initialize opts structure if it doesn't exist
			opts = opts or {}
			opts.routes = opts.routes or {}
			opts.presets = opts.presets or {}

			table.insert(opts.routes, {
				filter = {
					event = "notify",
					find = "No information available",
				},
				opts = { skip = true },
			})

			local focused = true
			vim.api.nvim_create_autocmd("FocusGained", {
				callback = function()
					focused = true
				end,
			})
			vim.api.nvim_create_autocmd("FocusLost", {
				callback = function()
					focused = false
				end,
			})

			table.insert(opts.routes, 1, {
				filter = {
					cond = function()
						return not focused
					end,
				},
				view = "notify_send",
				opts = { stop = false },
			})

			opts.commands = {
				all = {
					-- options for the message history that you get with `:Noice`
					view = "split",
					opts = { enter = true, format = "details" },
					filter = {},
				},
			}

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "markdown",
				callback = function(event)
					vim.schedule(function()
						require("noice.text.markdown").keys(event.buf)
					end)
				end,
			})

			opts.presets.lsp_doc_border = true

			return opts
		end,
	},

	{
		"rcarriga/nvim-notify",
		opts = function()
			return {
				timeout = 5000,
				-- the colorscheme is transparent, so notify blends its fade over this
				background_colour = palette().bg,
			}
		end,
	},

	-- buffer line
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		keys = {
			{ "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
			{ "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
		},
		opts = {
			options = {
				mode = "tabs",
				-- separator_style = "slant",
				show_buffer_close_icons = false,
				show_close_icon = false,
			},
		},
	},

	-- filename
	{
		"b0o/incline.nvim",
		event = "BufReadPre",
		priority = 1200,
		config = function()
			local c = palette()
			require("incline").setup({
				highlight = {
					groups = {
						-- active matches lualine's normal-mode block
						InclineNormal = { guibg = c.yellow, guifg = c.bg },
						InclineNormalNC = { guifg = c.fg_gutter_ui, guibg = c.bg_dark },
					},
				},
				window = { margin = { vertical = 0, horizontal = 1 } },
				hide = {
					cursorline = true,
				},
				render = function(props)
					local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
					if vim.bo[props.buf].modified then
						filename = "[+] " .. filename
					end

					local icon, color = require("nvim-web-devicons").get_icon_color(filename)
					return { { icon, guifg = color }, { " " }, { filename } }
				end,
			})
		end,
	},

	-- statusline: lualine.lua

	{
		"folke/zen-mode.nvim",
		cmd = "ZenMode",
		opts = {},
		keys = { { "<leader>z", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		keys = {
			{ "<leader>o", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
		},
		opts = {},
	},

	-- snacks: loaded at startup, the dashboard is set up on UIEnter and
	-- would never show if the plugin waited for <leader>t
	{
		"folke/snacks.nvim",
		lazy = false,
		priority = 1000,
		keys = {
			{
				"<leader>t",
				function()
					Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.3 } })
				end,
				desc = "Toggle Terminal",
			},
		},
		opts = {
			scroll = { enabled = false },
			dashboard = {
				preset = {
					header = [[
	███████╗ ██████╗  ██████╗ ███████╗██████╗ ██╗███████╗██████╗ ██████╗ ██╗ ██████╗███████╗
	██╔════╝██╔════╝ ██╔════╝ ██╔════╝██╔══██╗██║██╔════╝██╔══██╗██╔══██╗██║██╔════╝██╔════╝
	█████╗  ██║  ███╗██║  ███╗█████╗  ██████╔╝██║█████╗  ██║  ██║██████╔╝██║██║     █████╗  
	██╔══╝  ██║   ██║██║   ██║██╔══╝  ██╔══██╗██║██╔══╝  ██║  ██║██╔══██╗██║██║     ██╔══╝  
	███████╗╚██████╔╝╚██████╔╝██║     ██║  ██║██║███████╗██████╔╝██║  ██║██║╚██████╗███████╗
	╚══════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝
]],
				},
			},
		},
	},
}
