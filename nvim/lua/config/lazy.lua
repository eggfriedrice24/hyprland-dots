local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
	-- start lazy.nvim itself at the commit lazy-lock.json pins, like every plugin it restores;
	-- otherwise a new machine runs the newest stable, Lazy writes that into the tracked lock file
	-- and the checkout is dirty
	local ok, lock = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(vim.fn.stdpath("config") .. "/lazy-lock.json"), "\n"))
	end)
	local commit = ok and lock["lazy.nvim"] and lock["lazy.nvim"].commit
	if commit then
		vim.fn.system({ "git", "-C", lazypath, "checkout", "--quiet", commit })
	end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = { import = "plugins" },
	install = {
		colorscheme = { "eggfriedrice", "default" },
	},
	ui = {
		border = "rounded",
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
})
