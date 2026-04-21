local parsers = {
	"astro",
	"bash",
	"c",
	"cmake",
	"cpp",
	"css",
	"gitignore",
	"go",
	"graphql",
	"html",
	"http",
	"java",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"php",
	"python",
	"query",
	"regex",
	"rust",
	"scss",
	"sql",
	"svelte",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})
			require("nvim-treesitter").install(parsers)

			vim.treesitter.language.register("markdown", "mdx")

			vim.api.nvim_create_autocmd("FileType", {
				callback = function(ev)
					local ft = vim.bo[ev.buf].filetype
					local lang = vim.treesitter.language.get_lang(ft)
					if lang and pcall(vim.treesitter.language.add, lang) then
						pcall(vim.treesitter.start, ev.buf, lang)
					end
				end,
			})
		end,
	},

	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},
}
