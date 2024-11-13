-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {

	{ "ryvnf/readline.vim", event = "VeryLazy", },



	"ecthelionvi/NeoSwap",
	{ "vim-utils/vim-all", event = "VeryLazy", },

	{
		"johmsalas/text-case.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("textcase").setup({})
			require("telescope").load_extension("textcase")
		end,
		keys = {
			{ "ga", desc = "Change case" },
			{ "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "List case options" },
		},
	},
}
