return {
	-- Formatter
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "never" })
				end,
				mode = { "n", "v" },
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				handlebars = { "prettier" },
				go = { "goimports", "gofumpt" },
				rust = { "rustfmt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
				java = { "google-java-format" },
			},
			format_on_save = {
				timeout_ms = 3000,
				lsp_format = "never",
				quiet = true,
			},
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
				prettier = {
					timeout_ms = 3000,
					require_cwd = true,
				},
			},
		},
		init = function()
			-- If you want the formatters to have priority over the LSP
			-- you can set this option to true
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- Linter
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				python = { "flake8" },
				lua = { "selene" },
				go = { "golangci-lint" },
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
			}

			-- Create autocommand which carries out the actual linting
			-- on the specified events.
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					-- Only run linter if file is not too large (> 100KB)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(0))
					if ok and stats and stats.size > max_filesize then
						return
					end

					-- Safely try linting, ignore errors if linter not found
					pcall(lint.try_lint)
				end,
			})

		end,
	},

	-- Better quickfix window
	{
		"kevinhwang91/nvim-bqf",
		ft = "qf",
		opts = {},
	},

	-- Trouble - better diagnostics list
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{ "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
			{ "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
		},
	},
}
