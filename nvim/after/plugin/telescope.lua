local status_ok, telescope = pcall(require, "telescope")
if not status_ok then
	return
end

local actions = require("telescope.actions")
local fb_actions = require("telescope").extensions.file_browser.actions

-- Telescope setup
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
						for i = 1, 10 do
							actions.move_selection_previous(prompt_bufnr)
						end
					end,
					["<C-d>"] = function(prompt_bufnr)
						for i = 1, 10 do
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

-- Load extensions
require("telescope").load_extension("fzf")
require("telescope").load_extension("file_browser")

-- Telescope keymaps
local builtin = require("telescope.builtin")

-- Helper function for telescope buffer directory
local function telescope_buffer_dir()
	return vim.fn.expand("%:p:h")
end

-- File operations
vim.keymap.set("n", "fP", function()
	builtin.find_files({
		cwd = require("lazy.core.config").options.root,
	})
end, { desc = "Find Plugin File" })

vim.keymap.set("n", "ff", function()
	builtin.find_files({
		no_ignore = false,
		hidden = true,
	})
end, { desc = "Lists files in your current working directory, respects .gitignore" })

vim.keymap.set("n", "ft", function()
	builtin.live_grep({
		additional_args = { "--hidden" },
	})
end, {
	desc = "Search for a string in your current working directory and get results live as you type, respects .gitignore",
})

-- Buffer operations
vim.keymap.set("n", "\\\\", function()
	builtin.buffers()
end, { desc = "Lists open buffers" })

-- Help and documentation
vim.keymap.set("n", "ht", function()
	builtin.help_tags()
end, { desc = "Lists available help tags and opens a new window with the relevant help info on <cr>" })

-- Resume and navigation
vim.keymap.set("n", ";;", function()
	builtin.resume()
end, { desc = "Resume the previous telescope picker" })

-- Diagnostics and LSP
vim.keymap.set("n", ";e", function()
	builtin.diagnostics()
end, { desc = "Lists Diagnostics for all open buffers or a specific buffer" })

vim.keymap.set("n", ";s", function()
	builtin.treesitter()
end, { desc = "Lists Function names, variables, from Treesitter" })

vim.keymap.set("n", ";c", function()
	builtin.lsp_incoming_calls()
end, { desc = "Lists LSP incoming calls for word under the cursor" })

-- File browser
vim.keymap.set("n", "sf", function()
	telescope.extensions.file_browser.file_browser({
		path = "%:p:h",
		cwd = telescope_buffer_dir(),
		respect_gitignore = false,
		hidden = true,
		grouped = true,
		previewer = false,
		initial_mode = "normal",
		layout_config = { height = 40 },
	})
end, { desc = "Open File Browser with the path of the current buffer" })
