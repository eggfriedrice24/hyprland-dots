return {
	-- tools
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {},
	},

	-- Auto-install Mason tools
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				-- Language Servers
				"lua-language-server",
				"gopls",
				"typescript-language-server",
				"css-lsp",
				"tailwindcss-language-server",
				"html-lsp",
				"yaml-language-server",
				"jdtls",
				"basedpyright",

				-- Formatters
				"stylua",
				"prettier",
				"black",
				"isort",
				"gofumpt",
				"goimports",
				"google-java-format",

				-- Linters
				"eslint-lsp",
				"selene",
				"shellcheck",
				"golangci-lint",
				"markdownlint",
			},
		},
	},
	-- lsp servers
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			-- Tailwind CSS Language Server
			vim.lsp.config("tailwindcss", {
				root_markers = { ".git" },
			})

			-- TypeScript Language Server
			vim.lsp.config("ts_ls", {
				root_markers = { ".git" },
				single_file_support = true,
				settings = {
					typescript = {
						inlayHints = {
							includeInlayParameterNameHints = "literal",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = false,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
					javascript = {
						inlayHints = {
							includeInlayParameterNameHints = "all",
							includeInlayParameterNameHintsWhenArgumentMatchesName = false,
							includeInlayFunctionParameterTypeHints = true,
							includeInlayVariableTypeHints = true,
							includeInlayPropertyDeclarationTypeHints = true,
							includeInlayFunctionLikeReturnTypeHints = true,
							includeInlayEnumMemberValueHints = true,
						},
					},
				},
			})

			-- Emmet Language Server
			vim.lsp.config("emmet_language_server", {
				filetypes = { "html", "css", "scss", "javascriptreact", "typescriptreact", "svelte", "astro" },
			})

			-- YAML Language Server
			vim.lsp.config("yamlls", {
				settings = {
					yaml = {
						keyOrdering = false,
					},
				},
			})

			-- ESLint Language Server (linting + formatting for JS/TS)
			vim.lsp.config("eslint", {
				settings = {
					eslint = {
						useFlatConfig = true,
						run = "onSave",
					},
				},
				on_attach = function(client, bufnr)
					vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
						client:request_sync("workspace/executeCommand", {
							command = "eslint.applyAllFixes",
							arguments = {
								{
									uri = vim.uri_from_bufnr(bufnr),
									version = vim.lsp.util.buf_versions[bufnr],
								},
							},
						}, 5000, bufnr)
					end, {})
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						command = "LspEslintFixAll",
					})
				end,
			})

			-- Lua Language Server
			vim.lsp.config("lua_ls", {
				single_file_support = true,
				settings = {
					Lua = {
						workspace = {
							checkThirdParty = false,
						},
						completion = {
							workspaceWord = true,
							callSnippet = "Both",
						},
						misc = {
							parameters = {
								-- "--log-level=trace",
							},
						},
						hint = {
							enable = true,
							setType = false,
							paramType = true,
							paramName = "Disable",
							semicolon = "Disable",
							arrayIndex = "Disable",
						},
						doc = {
							privateName = { "^_" },
						},
						type = {
							castNumberToInteger = true,
						},
						diagnostics = {
							disable = { "incomplete-signature-doc", "trailing-space" },
							globals = { "vim" }, -- Add vim global
							groupSeverity = {
								strong = "Warning",
								strict = "Warning",
							},
							groupFileStatus = {
								["ambiguity"] = "Opened",
								["await"] = "Opened",
								["codestyle"] = "None",
								["duplicate"] = "Opened",
								["global"] = "Opened",
								["luadoc"] = "Opened",
								["redefined"] = "Opened",
								["strict"] = "Opened",
								["strong"] = "Opened",
								["type-check"] = "Opened",
								["unbalanced"] = "Opened",
								["unused"] = "Opened",
							},
							unusedLocalExclude = { "_*" },
						},
						format = {
							enable = false, -- Disable LSP formatting in favor of stylua
							defaultConfig = {
								indent_style = "space",
								indent_size = "2",
								continuation_indent_size = "2",
							},
						},
					},
				},
			})

			-- Basedpyright Language Server
			vim.lsp.config("basedpyright", {
				settings = {
					basedpyright = {
						analysis = {
							typeCheckingMode = "standard",
							autoImportCompletions = true,
						},
					},
				},
			})

			-- Enable all servers
			vim.lsp.enable({
				"cssls",
				"tailwindcss",
				"ts_ls",
				"html",
				"emmet_language_server",
				"yamlls",
				"gopls",
				"jdtls",
				"eslint",
				"lua_ls",
				"basedpyright",
			})
		end,
	},
}
