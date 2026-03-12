-- TODO: add count before `g` or between `g` and `>`/`<` to swap multiple times
-- TODO: remove line below

vim = vim

_G._swap_info = { count = 1, direction = 1 }

_G._swap_word = function()
	local count = vim.v.count > 0 and vim.v.count or _G._swap_info.count
	local dir = _G._swap_info.direction
	_G._swap_info.count = count

	local start_col = vim.api.nvim_win_get_cursor(0)[2]
	vim.cmd("normal! eb")
	local delta_col = start_col - vim.api.nvim_win_get_cursor(0)[2]

	-- If backward, jump the cursor back N words first
	if dir == -1 then
		vim.fn.search([[\v%(\w+\_W+){]] .. count .. [[}%#]], "cb")
	end

	local gap = [[\_W+%(\w+\_W+){]] .. (count - 1) .. [[}]]
	local regex = [[\v(%#\w+)(]] .. gap .. [[)(\w+)]]
	local cmd = [[keeppattern s/]] .. regex .. [[/\3\2\1/ | normal! ``]]

	local status, _ = pcall(vim.cmd, cmd)
	if dir == 1 and status then
		vim.fn.search([[\v%#%(\w+\_W+){]] .. count .. [[}\w]], "ce")
	end

	if delta_col > 0 then
		vim.cmd("normal! " .. delta_col .. "l")
	end
end

_G._swap_Word = function()
	local count = vim.v.count > 0 and vim.v.count or _G._swap_info.count
	local dir = _G._swap_info.direction
	_G._swap_info.count = count

	local start_col = vim.api.nvim_win_get_cursor(0)[2]
	vim.cmd("normal! EB")
	local delta_col = start_col - vim.api.nvim_win_get_cursor(0)[2]

	-- If backward, jump the cursor back N words first
	if dir == -1 then
		vim.fn.search([[\v%(\S+\_W+){]] .. count .. [[}%#]])
	end

	local gap = [[\_W+%(\S+\_W+){]] .. (count - 1) .. [[}]]
	local regex = [[\v(%#\S+)(]] .. gap .. [[)(\S+)]]
	local cmd = [[keeppattern s/]] .. regex .. [[/\3\2\1/ | normal! ``]]

	local status, _ = pcall(vim.cmd, cmd)
	if dir == 1 and status then
		vim.fn.search([[\v%#%(\S+\_W+){]] .. count .. [[}\S]], "ce")
	end

	if delta_col > 0 then
		vim.cmd("normal! " .. delta_col .. "l")
	end
end

_G._swap_paragraph = function()
	local count = vim.v.count > 0 and vim.v.count or _G._swap_info.count
	local dir = _G._swap_info.direction
	_G._swap_info.count = count

	local reginfo = vim.fn.getreginfo("y")
	local start_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd('normal! "_yap')
	local ppos = vim.api.nvim_win_get_cursor(0)

	local move_cmd
	if dir == 1 then
		move_cmd = "}"
	else
		move_cmd = "{{"
	end
	vim.cmd('normal! "ydap')
	vim.cmd("undojoin")
	vim.cmd("normal! " .. count .. move_cmd .. '"yp0')

	local cur_pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_win_set_cursor(0, { cur_pos[1] + start_pos[1] - ppos[1], cur_pos[2] + start_pos[2] - ppos[2] })

	vim.fn.setreg("y", reginfo)
end

_G._swap_next_paragraph = function()
	local reginfo = vim.fn.getreginfo("y")
	local start_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd('normal! "_yap')
	local ppos = vim.api.nvim_win_get_cursor(0)

	vim.cmd('normal! "ydap')
	vim.cmd("undojoin")
	vim.cmd('normal! }"yp0')

	local cur_pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_win_set_cursor(0, { cur_pos[1] + start_pos[1] - ppos[1], cur_pos[2] + start_pos[2] - ppos[2] })

	vim.fn.setreg("y", reginfo)
end

_G._swap_prev_paragraph = function()
	local reginfo = vim.fn.getreginfo("y")
	local start_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd('normal! "_yap')
	local ppos = vim.api.nvim_win_get_cursor(0)

	vim.cmd('normal! "ydap')
	vim.cmd("undojoin")
	vim.cmd('normal! {{"yp0')

	local cur_pos = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_win_set_cursor(0, { cur_pos[1] + start_pos[1] - ppos[1], cur_pos[2] + start_pos[2] - ppos[2] })

	vim.fn.setreg("y", reginfo)
end

local function set_swap_mappings()
	vim.keymap.set("n", "g>w", function()
		_G._swap_info.direction = 1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_word"
		return "g@l"
	end, { expr = true, desc = "Swap next word", silent = true })

	vim.keymap.set("n", "g<w", function()
		_G._swap_info.direction = -1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_word"
		return "g@l"
	end, { expr = true, desc = "Swap prev word", silent = true })

	vim.keymap.set("n", "g>W", function()
		_G._swap_info.direction = 1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_Word"
		return "g@l"
	end, { expr = true, desc = "Swap next Word", silent = true })

	vim.keymap.set("n", "g<W", function()
		_G._swap_info.direction = -1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_Word"
		return "g@l"
	end, { expr = true, desc = "Swap prev Word", silent = true })

	-- -- Swap paragraphs using regex
	-- vim.keymap.set("n", "g>p", function()
	-- 	vim.go.operatorfunc = "v:lua._swap_next_paragraph"
	-- 	return "g@l"
	-- end, { expr = true, desc = "Swap next Paragraph", silent = true })

	-- vim.keymap.set("n", "g<p", function()
	-- 	vim.go.operatorfunc = "v:lua._swap_prev_paragraph"
	-- 	return "g@l"
	-- end, { expr = true, desc = "Swap prev Paragraph", silent = true })

	-- Swap paragraphs using regex
	vim.keymap.set("n", "g>p", function()
		_G._swap_info.direction = 1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_paragraph"
		return "g@l"
	end, { expr = true, desc = "Swap next Paragraph", silent = true })

	vim.keymap.set("n", "g<p", function()
		_G._swap_info.direction = -1
		_G._swap_info.count = vim.v.count1
		vim.go.operatorfunc = "v:lua._swap_paragraph"
		return "g@l"
	end, { expr = true, desc = "Swap prev Paragraph", silent = true })

	-- Swap treesitter text objects
	local ts_swap = require("nvim-treesitter-textobjects.swap")
	local keys = {
		["f"] = "@function.outer",
		["c"] = "@class.outer",
		["a"] = "@parameter.inner",
	}
	for key, query in pairs(keys) do
		local operand = query:gsub("@", ""):gsub("%..*", "")
		operand = operand:sub(1, 1):upper() .. operand:sub(2)
		vim.keymap.set({ "n", "x", "o" }, "g>" .. key, function()
			ts_swap.swap_next(query)
		end, { desc = "Swap next " .. operand, silent = true })
		vim.keymap.set({ "n", "x", "o" }, "g<" .. key, function()
			ts_swap.swap_previous(query)
		end, { desc = "Swap prev " .. operand, silent = true })
	end
end

local M = {
	event = "BufReadPost",
	dir = vim.fn.stdpath("config") .. "/lua/plugins",
	name = "object_swap",
	dev = true,
	config = set_swap_mappings,
}

return M
