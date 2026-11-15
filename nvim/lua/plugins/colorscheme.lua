-- eggfriedrice: the local checkout when present (theme development), GitHub otherwise
local local_dir = vim.fn.expand("~/p/eggfriedrice.nvim")

return {
	{
		"eggfriedrice24/eggfriedrice.nvim",
		dir = vim.fn.isdirectory(local_dir) == 1 and local_dir or nil,
		priority = 1000,
		lazy = false,
		config = function()
			require("eggfriedrice").setup({
				transparent = true,
			})

			vim.cmd.colorscheme("eggfriedrice")
		end,
	},
}
