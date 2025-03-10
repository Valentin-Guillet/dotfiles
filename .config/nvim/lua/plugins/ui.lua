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
				lualine_y = { "%3l/%L %3c|" },
			},
		},
	},

	{ "akinsho/bufferline.nvim", enabled = false },
}
