return {
	-- {
	-- 	-- "eggfriedrice24/eggfriedrice.nvim",
	-- 	dir = "/home/eggfriedrice/p/eggfriedrice.nvim",
	-- 	priority = 1000,
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("eggfriedrice").setup({
	-- 			transparent = true,
	-- 		})
	--
	-- 		vim.cmd.colorscheme("eggfriedrice")
	-- 	end,
	-- },
	-- {
	-- 	"olimorris/onedarkpro.nvim",
	-- 	priority = 1000,
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("onedarkpro").setup({
	-- 			options = {
	-- 				transparency = true,
	-- 			},
	-- 		})
	--
	-- 		vim.cmd.colorscheme("onedark")
	-- 	end,
	-- },
	-- {
	-- 	"rose-pine/neovim",
	-- 	name = "rose-pine",
	-- 	priority = 1000,
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("rose-pine").setup({
	-- 			styles = {
	-- 				transparency = true,
	-- 			},
	-- 		})
	--
	-- 		vim.cmd.colorscheme("rose-pine")
	-- 	end,
	-- },
	{
		"tiagovla/tokyodark.nvim",
		priority = 1000,
		lazy = false,
		config = function()
			require("tokyodark").setup({
				transparent_background = true,
			})

			vim.cmd.colorscheme("tokyodark")
		end,
	},
}
