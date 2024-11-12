return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {
					settings = {
						python = {
							pythonPath = vim.env.HOME .. "/.local/venv/bin/python",
						},
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
