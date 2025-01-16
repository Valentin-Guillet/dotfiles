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

	{
		"neovim/nvim-lspconfig",
		opts = function()
			local keys = require("lazyvim.plugins.lsp.keymaps").get()
			-- Remove to let <C-k> scroll documentation in Noice
			keys[#keys + 1] = { "<C-k>", false, mode = "i" }
		end
	},
}
