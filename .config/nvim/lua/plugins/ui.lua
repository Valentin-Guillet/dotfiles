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
		opts = {
			sections = {
				lualine_b = {
					{
						get_venv_name,
						cond = function()
							return vim.bo.filetype == "python"
						end,
						icon = "󰌠",
						color = { fg = "#FFD43B" },
					},
					"branch",
				},
				lualine_c = {
					LazyVim.lualine.root_dir(),
					{
						"diagnostics",
						symbols = {
							error = LazyVim.config.icons.diagnostics.Error,
							warn = LazyVim.config.icons.diagnostics.Warn,
							info = LazyVim.config.icons.diagnostics.Info,
							hint = LazyVim.config.icons.diagnostics.Hint,
						},
					},
					{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
					{ LazyVim.lualine.pretty_path({ length = 0 }) },
				},
				lualine_y = { "%3l/%L %3c|" },
			},
		},
	},

	{ "akinsho/bufferline.nvim", enabled = false },
}
