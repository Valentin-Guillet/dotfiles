local M = {
	"nvim-mini/mini.comment",
	_dup_after = nil,
}

local function get_region(mode)
	if mode == "v" or mode == "V" or mode == "" then
		return vim.api.nvim_buf_get_mark(0, "<")[1], vim.api.nvim_buf_get_mark(0, ">")[1]
	end
	return vim.api.nvim_buf_get_mark(0, "[")[1], vim.api.nvim_buf_get_mark(0, "]")[1]
end

M.comment_fn = function(mode, dup_after)
	dup_after = dup_after or M._dup_after
	local cursor_pos = M._cursor_pos or vim.api.nvim_win_get_cursor(0)
	local start_ln, end_ln = get_region(mode)
	local lines = vim.api.nvim_buf_get_lines(0, start_ln - 1, end_ln, false)

	require("mini.comment").toggle_lines(start_ln, end_ln)

	if dup_after then -- Duplicate below
		vim.api.nvim_buf_set_lines(0, end_ln, end_ln, false, lines)
		cursor_pos[1] = cursor_pos[1] + end_ln + 1 - start_ln
	else -- Duplicate above (original lines become the uncommented ones)
		vim.api.nvim_buf_set_lines(0, start_ln - 1, start_ln - 1, false, lines)
	end

	vim.api.nvim_win_set_cursor(0, cursor_pos)
	M._cursor_pos = nil
end

local function set_comment_operator(dup_after)
	local plug = require("plugins.comment_duplicate")
	plug._dup_after = dup_after
	plug._cursor_pos = vim.api.nvim_win_get_cursor(0) -- Must save curpos before executing movement
	vim.go.operatorfunc = "v:lua.require'plugins.comment_duplicate'.comment_fn"
	return "g@"
end

M.keys = {
	{
		"gs",
		function()
			return set_comment_operator(true)
		end,
		expr = true,
		desc = "Comment and Duplicate Below",
	},
	{
		"gs",
		function()
			vim.cmd("normal! \27") -- exit visual mode to update marks
			M.comment_fn(vim.fn.visualmode(), true)
		end,
		mode = "x",
		desc = "Comment and Duplicate Selection",
	},

	{
		"gS",
		function()
			return set_comment_operator(false)
		end,
		expr = true,
		desc = "Duplicate Above and Comment",
	},
	{
		"gS",
		function()
			vim.cmd("normal! \27") -- exit visual mode to update marks
			M.comment_fn(vim.fn.visualmode(), false)
		end,
		mode = "x",
		desc = "Duplicate Above and Comment Selection",
	},

	{ "gss", "gs_", remap = true, desc = "Comment and Duplicate Line" },
	{ "gsS", "gS_", remap = true, desc = "Duplicate Above and Comment Line" },
	{ "gSS", "gS_", remap = true, desc = "Duplicate Above and Comment Line" },
}

return M
