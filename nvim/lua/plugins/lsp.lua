return {
	-- tools
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				-- Language Servers
				"lua-language-server",
				"typescript-language-server",
				"css-lsp",
				"tailwindcss-language-server",
				"html-lsp",
				"yaml-language-server",

				-- Formatters
				"stylua",
				"prettier",
				"black",
				"isort",
				"gofumpt",
				"goimports",
				"rustfmt",

				-- Linters
				"luacheck",
				"selene",
				"eslint_d",
				"shellcheck",
				"flake8",
				"golangci-lint",
				"markdownlint",
			},
		},
	},
	-- lsp servers
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local lspconfig = require("lspconfig")

			-- CSS Language Server
			lspconfig.cssls.setup({})

			-- Tailwind CSS Language Server
			lspconfig.tailwindcss.setup({
				root_dir = function(...)
					return require("lspconfig.util").root_pattern(".git")(...)
				end,
			})

			-- TypeScript Language Server
			lspconfig.ts_ls.setup({
				root_dir = function(...)
					return require("lspconfig.util").root_pattern(".git")(...)
				end,
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

			-- HTML Language Server
			lspconfig.html.setup({})

			-- YAML Language Server
			lspconfig.yamlls.setup({
				settings = {
					yaml = {
						keyOrdering = false,
					},
				},
			})

			-- Lua Language Server
			lspconfig.lua_ls.setup({
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
		end,
	},
}
