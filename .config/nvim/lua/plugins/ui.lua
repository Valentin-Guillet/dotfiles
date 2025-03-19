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
