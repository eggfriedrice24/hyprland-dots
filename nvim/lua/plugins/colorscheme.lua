return {
	{
		-- "eggfriedrice24/eggfriedrice.nvim",
		dir = "/home/eggfriedrice/p/eggfriedrice.nvim",
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
