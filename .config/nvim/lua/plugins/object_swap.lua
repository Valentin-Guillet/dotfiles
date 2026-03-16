_G._dynamic_move_state = { count = 1, dir = 1, obj = "", jump = { fwd = "", bwd = "" } }

local motion_map = {
	["w"] = { fwd = "w", bwd = "b", default = "i" },
	["W"] = { fwd = "W", bwd = "B", default = "i" },
	["p"] = { fwd = "}}k", bwd = "{{j", default = "i" },
	["s"] = { fwd = ")", bwd = "(", default = "i" },
	["f"] = { fwd = "]f", bwd = "[f", default = "a" },
	["a"] = { fwd = "]a", bwd = "[a", default = "a" },
	["c"] = { fwd = "]c", bwd = "[c", default = "a" },
}

local function get_obj_range(obj)
	local old_pos = vim.api.nvim_win_get_cursor(0)
	vim.cmd("normal v" .. obj .. "\27")
	vim.api.nvim_win_set_cursor(0, old_pos)

	local start_pos = vim.fn.getpos("'<") -- [buf, line, col, off]
	local end_pos = vim.fn.getpos("'>")

	if end_pos[3] == 1 and vim.fn.getline(end_pos[2]) == "" then -- Empty line
		end_pos[3] = 0
	elseif end_pos[3] == 2147483647 then -- End of line if col is max int
		end_pos[3] = vim.fn.col({ end_pos[2], "$" }) - 1
	end

	-- API uses 0-indexed lines and columns.
	-- end_pos column needs to be +1 because nvim_buf_get_text is end-exclusive.
	return {
		s_row = start_pos[2] - 1,
		s_col = start_pos[3] - 1,
		e_row = end_pos[2] - 1,
		e_col = end_pos[3],
	}
end

local function get_end_pos(s_row, s_col, text_table)
	local rows = #text_table
	if rows == 1 then
		return s_row, s_col + #text_table[1]
	else
		return s_row + rows - 1, #text_table[rows]
	end
end

local function prompt_dynamic_move()
	local dir = _G._dynamic_move_state.dir
	local count = vim.v.count1
	local succ, obj = pcall(vim.fn.getcharstr)
	if not succ or not obj or obj == "\27" then
		return false
	end

	local mod = ""
	local jump
	if obj == "i" or obj == "a" then -- explicit modifier
		mod = obj
		succ, obj = pcall(vim.fn.getcharstr) -- get object
		if not succ or not obj or obj == "\27" then
			return false
		end

		jump = motion_map[mod .. obj]
		if not jump then -- modifier + object combo not defined, try without modifier
			jump = motion_map[obj]
			if not jump then -- object alone not defined either, give up
				print("No jump defined in motion_map for text object: " .. mod .. obj)
				return false
			end
		end
	else -- no explicit modifier, check if object alone is defined in motion_map
		jump = motion_map[obj]
		if not jump then
			print("No jump defined in motion_map for text object: " .. obj)
			return false
		end
		mod = jump.default -- get default modifier
	end
	obj = mod .. obj

	_G._dynamic_move_state = { count = count, dir = dir, obj = obj, jump = jump }
	return true
end

local manual_trigger = false -- track if mapping has been triggered directly or by '.' (repeat)

_G._execute_dynamic_swap = function()
	local state
	if manual_trigger then
		manual_trigger = false
		if not prompt_dynamic_move() then -- aborted
			return
		end
	end
	state = _G._dynamic_move_state

	local buf = 0

	local cur_pos = vim.api.nvim_win_get_cursor(0)
	local first = get_obj_range(state.obj)

	local move_cmd
	if state.dir == 1 then
		move_cmd = state.jump.fwd
	else
		local a_obj = "a" .. state.obj:sub(2)
		vim.cmd('normal "_y' .. a_obj) -- go to start of object
		move_cmd = state.jump.bwd
	end

	if state.obj == "iw" then -- special case for word motions to ensure we jump to the correct place when swapping
		if state.dir == 1 then
			vim.fn.search([[\v%#%(\w+\_W+){]] .. state.count .. [[}\w]], "ce")
		else
			vim.fn.search([[\v%(\w+\_W*){]] .. state.count .. [[}%#]], "cb")
		end
	else
		vim.cmd("normal " .. state.count .. move_cmd)
	end
	local second = get_obj_range(state.obj)

	local off_row = cur_pos[1] - 1 - first.s_row
	local off_col = (off_row == 0) and (cur_pos[2] - 1 - first.s_col) or cur_pos[2] - 1
	if state.dir < 0 then
		first, second = second, first
	end

	if second.s_row < first.e_row or (second.s_row == first.e_row and second.s_col < first.e_col) then
		if first.e_col == vim.fn.col({ first.e_row, "$" }) then
			second.s_row = first.e_row + 1
			second.s_col = 0
		else
			second.s_row = first.e_row
			second.s_col = first.e_col
		end
	end

	local text1 = vim.api.nvim_buf_get_text(buf, first.s_row, first.s_col, first.e_row, first.e_col, {})
	local gap = vim.api.nvim_buf_get_text(buf, first.e_row, first.e_col, second.s_row, second.s_col, {})
	local text2 = vim.api.nvim_buf_get_text(buf, second.s_row, second.s_col, second.e_row, second.e_col, {})

	local new_content = table.concat(text2, "\n") .. table.concat(gap, "\n") .. table.concat(text1, "\n")
	local final_lines = vim.split(new_content, "\n", { plain = true })
	vim.api.nvim_buf_set_text(buf, first.s_row, first.s_col, second.e_row, second.e_col, final_lines)

	local new_s_row, new_s_col
	if state.dir == 1 then
		local mid_row, mid_col = get_end_pos(first.s_row, first.s_col, text2)
		new_s_row, new_s_col = get_end_pos(mid_row, mid_col, gap)
	else
		new_s_row, new_s_col = first.s_row, first.s_col
	end

	local final_row = new_s_row + off_row
	local final_col = (off_row == 0) and (new_s_col + off_col) or off_col

	vim.api.nvim_win_set_cursor(0, { final_row + 1, final_col + 1 })
end

return {
	dir = vim.fn.stdpath("config") .. "/lua/plugins",
	name = "object_swap",
	dev = true,
	keys = {
		{
			"g>",
			function()
				manual_trigger = true
				_G._dynamic_move_state.dir = 1
				vim.go.operatorfunc = "v:lua._execute_dynamic_swap"
				return "g@l"
			end,
			expr = true,
			desc = "Move text object forward",
		},
		{
			"g<",
			function()
				manual_trigger = true
				_G._dynamic_move_state.dir = -1
				vim.go.operatorfunc = "v:lua._execute_dynamic_swap"
				return "g@l"
			end,
			expr = true,
			desc = "Move text object backward",
		},
	},
}
