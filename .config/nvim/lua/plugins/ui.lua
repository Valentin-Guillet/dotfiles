local function get_venv_name()
	local venv = vim.fn.getenv("VIRTUAL_ENV")
	if venv == vim.NIL then
		return ""
	end

	venv = string.gsub(venv, "(.*/)(.*)", "%2")
	if venv == "base" then
		return ""
	end

	return venv
end

return {
	{
		"folke/noice.nvim",
		keys = {
			{ "<C-f>", false, mode = "i" },
			{ "<C-b>", false, mode = "i" },
		},
		opts = {
			cmdline = {
				format = {
					help = {
						pattern = {
							"^:%s*he?l?p?%s+",
							"^:%s*verti?c?a?l? he?l?p?%s+",
							"^:%s*tab he?l?p?%s+",
						},
					},
				},
			},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			-- Add active python venv
			table.insert(opts.sections.lualine_b, 1, {
				get_venv_name,
				cond = function()
					return vim.bo.filetype == "python"
				end,
				icon = "󰌠",
				color = { fg = "#FFD43B" },
			})

			opts.sections.lualine_c[#opts.sections.lualine_c - 1] = { LazyVim.lualine.pretty_path({ length = 0 }) }
			opts.sections.lualine_y = { "%3l/%L %3c|" }
		end,
	},

	{ "akinsho/bufferline.nvim", enabled = false },
}
