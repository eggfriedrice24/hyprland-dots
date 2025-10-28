local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

-- Custom components
local function lsp_clients()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return ""
	end

	local client_names = {}
	for _, client in ipairs(clients) do
		table.insert(client_names, client.name)
	end

	return "󰒋 " .. table.concat(client_names, ", ")
end

local function modified_indicator()
	if vim.bo.modified then
		return "●"
	elseif vim.bo.modifiable == false or vim.bo.readonly == true then
		return "󰌾"
	end
	return ""
end

-- Setup lualine
lualine.setup({
	options = {
		theme = "auto",
		globalstatus = true,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = { "dashboard", "alpha", "starter" },
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
		},
	},
	sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(str)
					return str:sub(1, 1)
				end,
			},
		},
		lualine_b = {
			"branch",
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = " ", warn = " ", info = " ", hint = " " },
				diagnostics_color = {
					error = "DiagnosticError",
					warn = "DiagnosticWarn",
					info = "DiagnosticInfo",
					hint = "DiagnosticHint",
				},
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1, -- 0: Just filename, 1: Relative path, 2: Absolute path
				shorting_target = 40,
				symbols = {
					modified = "",
					readonly = "",
					unnamed = "[No Name]",
					newfile = "[New]",
				},
			},
			{
				modified_indicator,
				color = { fg = "#ff9e64" },
			},
		},
		lualine_x = {
			-- Optional: Noice integration (remove if you don't use noice)
			{
				function()
					return require("noice").api.status.command.get()
				end,
				cond = function()
					return package.loaded["noice"] and require("noice").api.status.command.has()
				end,
				color = { fg = "#ff9e64" },
			},
			{
				function()
					return require("noice").api.status.mode.get()
				end,
				cond = function()
					return package.loaded["noice"] and require("noice").api.status.mode.has()
				end,
				color = { fg = "#ff9e64" },
			},
			-- LSP clients
			{
				lsp_clients,
				color = { fg = "#7aa2f7" },
				cond = function()
					return #vim.lsp.get_clients({ bufnr = 0 }) > 0
				end,
			},
			-- File info
			{
				"encoding",
				cond = function()
					return vim.bo.fileencoding ~= "utf-8"
				end,
			},
			{
				"fileformat",
				cond = function()
					return vim.bo.fileformat ~= "unix"
				end,
			},
			"filetype",
		},
		lualine_y = {
			{
				"progress",
				fmt = function(str)
					return str == "Top" and "󰝣" or str == "Bot" and "󰝤" or str
				end,
			},
		},
		lualine_z = {
			{
				"location",
				fmt = function(str)
					return "󰍎 " .. str
				end,
			},
		},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {
		"neo-tree",
		"lazy",
		"mason",
		"trouble",
		"quickfix",
		"man",
	},
})
