return {
	{
		"folke/noice.nvim",
		keys = {
			{ "<c-f>", false, mode = "i" },
			{ "<c-b>", false, mode = "i" },
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

	{ "akinsho/bufferline.nvim", enabled = false },
}
