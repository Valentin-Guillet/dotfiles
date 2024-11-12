-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "text", "markdown", "sh", "bib", "tex" },
	callback = function() vim.opt_local.iskeyword:append("-") end,
})

vim.api.nvim_create_autocmd('CursorMoved', {
	callback = function ()
		if vim.v.hlsearch == 1 and vim.fn.searchcount().exact_match == 0 then
			vim.schedule(function() vim.cmd.nohlsearch() end)
		end
	end
})
