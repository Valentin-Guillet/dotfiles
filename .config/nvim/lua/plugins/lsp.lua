return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				clangd = {
					init_options = {
						fallbackFlags = { "-std=c++23" },
					},
				},
			},
		},
	},

	{
		"mrcjkb/rustaceanvim",
		opts = {
			server = {
				settings = {
					["rust-analyzer"] = {
						procMacro = {
							ignored = {
								["napi-derive"] = { "napi" },
								["async-recursion"] = { "async_recursion" },
							},
						},
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
		end,
	},
}
