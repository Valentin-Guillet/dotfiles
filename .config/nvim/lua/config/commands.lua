
local function diff_toggle()

  -- Get all windows in curr tab where buffer is listed
	local win_table = vim.tbl_filter(function(win)
		local buf = vim.api.nvim_win_get_buf(win)
		return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
	end, vim.api.nvim_tabpage_list_wins(0))

	if #win_table ~= 2 then
		vim.api.nvim_err_writeln("Can only diff two files")
		return
	end

	local diff_cmd
  if vim.wo.diff then
    diff_cmd = "diffoff"
  else
    diff_cmd = "diffthis"
  end
	for _, win in ipairs(win_table) do
    vim.api.nvim_win_call(win, function() vim.cmd(diff_cmd) end)
	end
end

vim.api.nvim_create_user_command("DiffToggle", diff_toggle, { desc = "Toggle diff mode" })
vim.keymap.set("n", "<leader>wf", diff_toggle, { desc = "Toggle diff mode" })


