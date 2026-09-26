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
	-- {
	-- 	"tiagovla/tokyodark.nvim",
	-- 	priority = 1000,
	-- 	lazy = false,
	-- 	config = function()
	-- 		require("tokyodark").setup({
	-- 			transparent_background = true,
	-- 		})
	--
	-- 		vim.cmd.colorscheme("tokyodark")
	-- 	end,
	-- },
}
