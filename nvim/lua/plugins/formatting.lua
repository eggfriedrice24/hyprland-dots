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
					args = {
						"--prose-wrap",
						"always",
						"--print-width",
						"120",
						"--parser",
						"markdown",
						"--stdin-filepath",
						"$FILENAME",
					},
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
			-- gq formats the motion with conform's formatters
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	-- Linter
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			-- the buffer arrives on stdin, so --stdin must stay
			lint.linters.markdownlint.args = { "--stdin", "--disable", "MD013" }

			-- no zsh entry: shellcheck only knows sh, bash, dash and ksh
			lint.linters_by_ft = {
				lua = { "selene" },
				go = { "golangcilint" },
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
			}

			-- An unknown name makes try_lint assert and skip the rest of the
			-- list, so drop it here and say so once instead of swallowing it.
			for ft, names in pairs(lint.linters_by_ft) do
				lint.linters_by_ft[ft] = vim.tbl_filter(function(name)
					if lint.linters[name] then
						return true
					end
					vim.notify_once(("nvim-lint: no linter named %q, skipping it"):format(name), vim.log.levels.WARN)
					return false
				end, names)
			end

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

					-- names were checked above; a missing executable is
					-- reported by nvim-lint itself
					lint.try_lint()

					-- Run oxlint for JS/TS when .oxlintrc.json exists in project
					local ft = vim.bo.filetype
					if vim.tbl_contains({ "javascript", "javascriptreact", "typescript", "typescriptreact" }, ft) then
						if vim.fs.find(".oxlintrc.json", { path = vim.fn.expand("%:p:h"), upward = true })[1] then
							lint.try_lint("oxlint")
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
		cmd = "Trouble",
		opts = {},
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Document Diagnostics (Trouble)",
			},
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace Diagnostics (Trouble)" },
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
		},
	},
}
