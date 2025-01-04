-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {

	{ "ryvnf/readline.vim", event = "VeryLazy", },

	{ "vim-utils/vim-all", event = "VeryLazy", },

	{
		"johmsalas/text-case.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{ "ga", desc = "Change case" },
		},
	},

	{
		"chentoast/marks.nvim",
		event = "VeryLazy",
		opts = {},
	}
}
