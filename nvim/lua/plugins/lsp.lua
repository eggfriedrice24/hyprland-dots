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
				"json-lsp",
				"typescript-language-server",
				"css-lsp",
				"tailwindcss-language-server",
				"html-lsp",
				"yaml-language-server",
				"jdtls",
				"basedpyright",
				"rust-analyzer",

				-- Formatters
				"stylua",
				"prettier",
				"black",
				"isort",
				"gofumpt",
				"goimports",
				"google-java-format",
				"rustfmt",

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
			-- JSON Language Server
			vim.lsp.config("jsonls", {
				single_file_support = true,
			})

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
			-- Only attaches when an ESLint config is found in the project
			vim.lsp.config("eslint", {
				root_markers = {
					"eslint.config.js",
					"eslint.config.mjs",
					"eslint.config.cjs",
					".eslintrc.json",
					".eslintrc.js",
					".eslintrc.yml",
					".eslintrc.yaml",
					".eslintrc",
				},
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

			-- Rust Analyzer
			-- rust-analyzer only indexes files inside a Cargo workspace (or a
			-- rust-project.json). For a standalone .rs file, root at its directory
			-- and load the .rs files there as detached files so completions and
			-- diagnostics still work.
			local rust_defaults = vim.lsp.config.rust_analyzer
			local rust_markers = { "Cargo.toml", "rust-project.json" }
			vim.lsp.config("rust_analyzer", {
				root_dir = function(bufnr, on_dir)
					local fname = vim.api.nvim_buf_get_name(bufnr)
					if vim.fs.root(fname, rust_markers) then
						return rust_defaults.root_dir(bufnr, on_dir)
					end
					on_dir(vim.fs.dirname(fname))
				end,
				before_init = function(params, config)
					rust_defaults.before_init(params, config)
					if not vim.fs.root(config.root_dir, rust_markers) then
						params.initializationOptions = vim.tbl_extend("force", params.initializationOptions or {}, {
							detachedFiles = vim.fn.glob(config.root_dir .. "/*.rs", true, true),
						})
					end
				end,
			})

			-- Enable all servers
			vim.lsp.enable({
				"cssls",
				"tailwindcss",
				"ts_ls",
				"html",
				"emmet_language_server",
				"jsonls",
				"yamlls",
				"gopls",
				"jdtls",
				"eslint",
				"lua_ls",
				"basedpyright",
				"rust_analyzer",
			})
		end,
	},
}
