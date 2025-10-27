return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				["*"] = {
					keys = {
						-- Remove keymap to let <C-k> scroll documentation in Noice
						{ "<C-k>", false, mode = "i" },
					},
				},
				clangd = {
					init_options = {
						fallbackFlags = { "-std=c++23" },
					},
				},
			},
		},
	},
}
