vim.api.nvim_create_autocmd("FileType", {
	pattern = { "text", "markdown", "sh", "bib", "tex" },
	callback = function() vim.opt_local.iskeyword:append("-") end,
})

vim.api.nvim_create_autocmd("CursorMoved", {
	callback = function()
		if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
			vim.schedule(vim.cmd.nohlsearch)
		end
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	callback = function()
		vim.b.diagnostic_status = vim.diagnostic.is_enabled()
		vim.diagnostic.enable(false)
	end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
	callback = function()
		vim.diagnostic.enable(vim.b.diagnostic_status)
		vim.b.diagnostic_status = nil
	end,
})
