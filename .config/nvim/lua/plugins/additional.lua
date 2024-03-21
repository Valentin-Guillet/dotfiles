-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {

	"mbbill/undotree",

	"ryvnf/readline.vim",

	"vim-utils/vim-all",

  "ecthelionvi/NeoSwap",

	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"ruff-lsp",
			},
		},
	},

  {
    "johmsalas/text-case.nvim",
    lazy = false,
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("textcase").setup({})
      require("telescope").load_extension("textcase")
    end,
    keys = {
      "ga", -- Default invocation prefix
      { "ga", desc = "Change case" },
      { "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "x" }, desc = "List case options" },
    },
  },
}
