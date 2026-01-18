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
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = { "n", "v" },
				desc = "Format buffer",
			},
		},
		opts = function()
			-- Helper: use eslint_d if ESLint config exists, otherwise prettier
			local function js_formatter(bufnr)
				local eslint_configs = { "eslint.config.mjs", "eslint.config.js", ".eslintrc.js", ".eslintrc.json", ".eslintrc" }
				if vim.fs.find(eslint_configs, { path = vim.api.nvim_buf_get_name(bufnr), upward = true })[1] then
					return { "eslint_d" }
				end
				return { "prettier" }
			end

			return {
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "isort", "black" },
					javascript = js_formatter,
					typescript = js_formatter,
					javascriptreact = js_formatter,
					typescriptreact = js_formatter,
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
				},
			format_on_save = {
				timeout_ms = 2000,
				lsp_fallback = true,
			},
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
				prettier = {
					timeout_ms = 3000,
				},
			},
		}
		end,
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
				javascript = { "eslint_d" },
				typescript = { "eslint_d" },
				javascriptreact = { "eslint_d" },
				typescriptreact = { "eslint_d" },
				vue = { "eslint_d" },
				python = { "flake8" },
				lua = { "luacheck" },
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
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(0))
					if ok and stats and stats.size > max_filesize then
						return
					end

					-- Safely try linting, ignore errors if linter not found
					pcall(lint.try_lint)
				end,
			})

			-- Lint on text change (with debounce)
			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				group = lint_augroup,
				callback = function()
					-- Debounce linting
					vim.defer_fn(function()
						pcall(lint.try_lint)
					end, 500)
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
