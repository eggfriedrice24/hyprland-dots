return {
	{
		enabled = false,
		"folke/flash.nvim",
		---@type Flash.Config
		opts = {
			search = {
				forward = true,
				multi_window = false,
				wrap = false,
				incremental = true,
			},
		},
	},

	{
		"brenoprata10/nvim-highlight-colors",
		event = "BufReadPre",
		opts = {
			render = "background",
			enable_hex = true,
			enable_short_hex = true,
			enable_rgb = true,
			enable_hsl = true,
			enable_hsl_without_function = true,
			enable_ansi = true,
			enable_var_usage = true,
			enable_tailwind = true,
		},
	},

	{
		"dinhhuy258/git.nvim",
		event = "BufReadPre",
		opts = {
			keymaps = {
				-- Open blame window
				blame = "<Leader>gb",
				-- Open file/folder in git repository
				browse = "<Leader>go",
			},
		},
		config = function(_, opts)
			require("git").setup(opts)

			vim.api.nvim_create_autocmd("BufWinEnter", {
				group = vim.api.nvim_create_augroup("GitDiffKeymaps", { clear = true }),
				callback = function(event)
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(event.buf) then
							return
						end

						local win = vim.fn.bufwinid(event.buf)
						if win == -1 or not vim.wo[win].diff then
							return
						end

						if vim.bo[event.buf].buftype ~= "nofile" or vim.bo[event.buf].bufhidden ~= "delete" then
							return
						end

						vim.keymap.set("n", "q", function()
							require("git.diff").close()
						end, { buffer = event.buf, silent = true, desc = "Close git diff" })
					end)
				end,
			})
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			"nvim-telescope/telescope-file-browser.nvim",
		},
		cmd = "Telescope",
		init = function()
			-- `nvim <dir>`: load now so file_browser takes the directory
			-- buffer over from netrw (it hijacks netrw once set up)
			if vim.fn.argc(-1) == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
				require("telescope")
			end
		end,
		keys = {
			{
				"fP",
				function()
					require("telescope.builtin").find_files({
						cwd = require("lazy.core.config").options.root,
					})
				end,
				desc = "Find Plugin File",
			},
			{
				"ff",
				function()
					require("telescope.builtin").find_files({
						no_ignore = false,
						hidden = true,
					})
				end,
				desc = "Lists files in your current working directory, respects .gitignore",
			},
			{
				"ft",
				function()
					require("telescope.builtin").live_grep({
						additional_args = { "--hidden" },
					})
				end,
				desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
			},
			{
				"\\\\",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Lists open buffers",
			},
			{
				"ht",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "Lists available help tags and opens a new window with the relevant help info on <cr>",
			},
			{
				";;",
				function()
					require("telescope.builtin").resume()
				end,
				desc = "Resume the previous telescope picker",
			},
			{
				";e",
				function()
					require("telescope.builtin").diagnostics()
				end,
				desc = "Lists Diagnostics for all open buffers or a specific buffer",
			},
			{
				";s",
				function()
					require("telescope.builtin").treesitter()
				end,
				desc = "Lists Function names, variables, from Treesitter",
			},
			{
				";c",
				function()
					require("telescope.builtin").lsp_incoming_calls()
				end,
				desc = "Lists LSP incoming calls for word under the cursor",
			},
			{
				"sf",
				function()
					require("telescope").extensions.file_browser.file_browser({
						path = "%:p:h",
						cwd = vim.fn.expand("%:p:h"),
						respect_gitignore = false,
						hidden = true,
						grouped = true,
						previewer = false,
						initial_mode = "normal",
						layout_config = { height = 40 },
					})
				end,
				desc = "Open File Browser with the path of the current buffer",
			},
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")
			local fb_actions = telescope.extensions.file_browser.actions

			telescope.setup({
				defaults = {
					wrap_results = true,
					layout_strategy = "horizontal",
					layout_config = { prompt_position = "top" },
					sorting_strategy = "ascending",
					winblend = 0,
					mappings = {
						n = {},
					},
				},
				pickers = {
					diagnostics = {
						theme = "ivy",
						initial_mode = "normal",
						layout_config = {
							preview_cutoff = 9999,
						},
					},
				},
				extensions = {
					file_browser = {
						theme = "dropdown",
						-- disables netrw and use telescope-file-browser in its place
						hijack_netrw = true,
						mappings = {
							["n"] = {
								-- your custom normal mode mappings
								["N"] = fb_actions.create,
								["h"] = fb_actions.goto_parent_dir,
								["/"] = function()
									vim.cmd("startinsert")
								end,
								["<C-u>"] = function(prompt_bufnr)
									for _ = 1, 10 do
										actions.move_selection_previous(prompt_bufnr)
									end
								end,
								["<C-d>"] = function(prompt_bufnr)
									for _ = 1, 10 do
										actions.move_selection_next(prompt_bufnr)
									end
								end,
								["<PageUp>"] = actions.preview_scrolling_up,
								["<PageDown>"] = actions.preview_scrolling_down,
							},
						},
					},
				},
			})

			telescope.load_extension("fzf")
			telescope.load_extension("file_browser")
		end,
	},

	{
		"kazhala/close-buffers.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<leader>bh",
				function()
					require("close_buffers").delete({ type = "hidden" })
				end,
				desc = "Close Hidden Buffers",
			},
			{
				"<leader>bu",
				function()
					require("close_buffers").delete({ type = "nameless" })
				end,
				desc = "Close Nameless Buffers",
			},
		},
	},

	{
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			keymap = {
				preset = "default",
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "fallback" },
				["<S-Tab>"] = { "select_prev", "fallback" },
				["<C-k>"] = { "select_prev", "fallback" },
				["<C-j>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
			},
			completion = {
				menu = {
					winblend = vim.o.pumblend,
				},
				accept = {
					auto_brackets = {
						enabled = true,
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
				},
			},
			signature = {
				enabled = true,
				window = {
					winblend = vim.o.pumblend,
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
		},
	},

	{
		"ThePrimeagen/harpoon",
		keys = {
			{
				"<leader>a",
				function()
					require("harpoon.mark").add_file()
				end,
				desc = "Harpoon: mark file",
			},
			{
				"<leader>p",
				function()
					require("harpoon.ui").toggle_quick_menu()
				end,
				desc = "Harpoon: quick menu",
			},
		},
	},
}
