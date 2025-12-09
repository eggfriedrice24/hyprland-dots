-- Configure diagnostics display
vim.diagnostic.config({
	virtual_text = {
		enabled = true,
		source = "if_many",
		prefix = "●",
		spacing = 2,
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.HINT] = "",
			[vim.diagnostic.severity.INFO] = "",
		},
	},
	underline = true,
	severity_sort = true,
	float = {
		focusable = true,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
		max_width = 80,
		max_height = 20,
	},
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local opts = { buffer = ev.buf, silent = true }

		-- Navigation keymaps
		vim.keymap.set("n", "gd", function()
			require("telescope.builtin").lsp_definitions({ reuse_win = false })
		end, vim.tbl_extend("force", opts, { desc = "Goto Definition" }))

		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Goto Declaration" }))

		vim.keymap.set("n", "gi", function()
			require("telescope.builtin").lsp_implementations({ reuse_win = false })
		end, vim.tbl_extend("force", opts, { desc = "Goto Implementation" }))

		vim.keymap.set("n", "gt", function()
			require("telescope.builtin").lsp_type_definitions({ reuse_win = false })
		end, vim.tbl_extend("force", opts, { desc = "Goto Type Definition" }))

		vim.keymap.set("n", "gr", function()
			require("telescope.builtin").lsp_references({ reuse_win = false })
		end, vim.tbl_extend("force", opts, { desc = "Find References" }))

		vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))

		-- Diagnostic keymaps
		vim.keymap.set(
			"n",
			"gl",
			vim.diagnostic.open_float,
			vim.tbl_extend("force", opts, { desc = "Show diagnostic" })
		)
		vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
		vim.keymap.set(
			"n",
			"[d",
			vim.diagnostic.goto_prev,
			vim.tbl_extend("force", opts, { desc = "Previous diagnostic" })
		)
		vim.keymap.set(
			"n",
			"<leader>q",
			vim.diagnostic.setloclist,
			vim.tbl_extend("force", opts, { desc = "Show diagnostics list" })
		)

		-- Telescope diagnostic keymaps
		vim.keymap.set("n", "<leader>wd", function()
			require("telescope.builtin").diagnostics()
		end, vim.tbl_extend("force", opts, { desc = "Workspace diagnostics" }))

		vim.keymap.set("n", "<leader>bd", function()
			require("telescope.builtin").diagnostics({ bufnr = 0 })
		end, vim.tbl_extend("force", opts, { desc = "Buffer diagnostics" }))

		-- Code action keymaps
		vim.keymap.set(
			{ "n", "v" },
			"<leader>ca",
			vim.lsp.buf.code_action,
			vim.tbl_extend("force", opts, { desc = "Code actions" })
		)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
	end,
})
