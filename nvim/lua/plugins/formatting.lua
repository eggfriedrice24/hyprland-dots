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
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = { "n", "v" },
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "oxfmt", "prettier", stop_after_first = true },
				javascriptreact = { "oxfmt", "prettier", stop_after_first = true },
				typescript = { "oxfmt", "prettier", stop_after_first = true },
				typescriptreact = { "oxfmt", "prettier", stop_after_first = true },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier_markdown" },
				mdx = { "prettier_markdown" },
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
				lsp_format = "fallback",
				quiet = true,
			},
			formatters = {
				shfmt = {
					prepend_args = { "-i", "2" },
				},
				oxfmt = {
					command = function(self, ctx)
						return require("conform.util").from_node_modules("oxfmt")(self, ctx)
					end,
					args = { "--stdin-filepath", "$FILENAME" },
					stdin = true,
					condition = function(_, ctx)
						return vim.fs.find(".oxfmtrc.json", { path = ctx.dirname, upward = true })[1] ~= nil
					end,
				},
				prettier_markdown = {
					command = "prettier",
					args = { "--prose-wrap", "always", "--print-width", "120", "--parser", "markdown", "--stdin-filepath", "$FILENAME" },
					stdin = true,
				},
				prettier = {
					timeout_ms = 3000,
					require_cwd = true,
					condition = function(_, ctx)
						return vim.fs.find({
							".prettierrc",
							".prettierrc.json",
							".prettierrc.yml",
							".prettierrc.yaml",
							".prettierrc.json5",
							".prettierrc.js",
							".prettierrc.cjs",
							".prettierrc.mjs",
							".prettierrc.toml",
							"prettier.config.js",
							"prettier.config.cjs",
							"prettier.config.mjs",
						}, { path = ctx.dirname, upward = true })[1] ~= nil
					end,
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

			lint.linters.markdownlint.args = {
				"--disable", "MD013", "--",
			}

			lint.linters_by_ft = {
				lua = { "selene" },
				go = { "golangci-lint" },
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
			}

			-- Resolve oxlint from nearest node_modules/.bin/ (monorepo-friendly)
			local oxlint = lint.linters.oxlint
			if oxlint then
				local original_cmd = oxlint.cmd
				oxlint.cmd = function()
					local node_bin = vim.fs.find("node_modules/.bin/oxlint", {
						path = vim.fn.expand("%:p:h"),
						upward = true,
					})[1]
					return node_bin or original_cmd
				end
			end

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

					-- Run oxlint for JS/TS when .oxlintrc.json exists in project
					local ft = vim.bo.filetype
					if vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, ft) then
						if vim.fs.find(".oxlintrc.json", { path = vim.fn.expand("%:p:h"), upward = true })[1] then
							pcall(lint.try_lint, "oxlint")
						end
					end
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
