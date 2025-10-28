vim.opt.backup = false

vim.opt.clipboard = "unnamedplus"

vim.opt.fileencoding = "utf-8"
vim.opt.encoding = "utf-8"

vim.opt.cmdheight = 1
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.mouse = ""
vim.opt.showmode = false
vim.opt.showtabline = 1
vim.opt.smarttab = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.splitkeep = "cursor"
vim.opt.swapfile = false
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.updatetime = 100
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.laststatus = 3
vim.opt.showcmd = true
vim.opt.relativenumber = true
vim.opt.wrap = false -- display lines as one long line
vim.opt.scrolloff = 10
vim.opt.title = true

vim.opt.fillchars:append({
	stl = " ",
})

vim.opt.shortmess:append("c")
vim.opt.formatoptions:append({ "r" })

vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])

vim.filetype.add({
	extension = {
		mdx = "mdx",
	},
})
