return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {
					settings = {
						python = {
							pythonPath = vim.env.HOME .. "/.local/venvs/base/bin/python",
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
