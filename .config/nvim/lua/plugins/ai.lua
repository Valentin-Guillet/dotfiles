return {
	{
		"zbirenbaum/copilot.lua",
		opts = {
			suggestion = {
				auto_trigger = false,
				keymap = {
					next = "<M-}>",
					prev = "<M-{>",
				},
			},
		},
	},

	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {},
		keys = {
			{ "<leader>ac", "<cmd>CodeCompanionChat Toggle<CR>", desc = "AI Chat" },
			{ "<leader>aa", "<cmd>CodeCompanionActions<CR>", desc = "AI Actions" },
			{ "<leader>ai", "<cmd>CodeCompanion<CR>", mode = { "n", "v" }, desc = "AI Inline Editing" },
			{ "<leader>am", "<cmd>CodeCompanion /commit<CR>", desc = "AI Commit" },
		},
	},
}
