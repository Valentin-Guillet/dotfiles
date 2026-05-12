return {
	{
		"saghen/blink.cmp",
		opts = {
			keymap = {
				-- Documentation scrolling is managed by `noice`
				["<C-b>"] = { "fallback" },
				["<C-f>"] = { "fallback" },
				["<C-e>"] = { "fallback" },
			},
		},
	},

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
		"kylechui/nvim-surround",
		event = "VeryLazy",
		init = function()
			-- Prevent definition of `S` and `gS` in visual mode
			-- We use `gS` in comment_duplicate local plugin, and we redefine `S` below
			vim.g.nvim_surround_no_visual_mappings = true
		end,
		keys = {
			{
				"S",
				"<Plug>(nvim-surround-visual)",
				mode = "x",
				desc = "Add a surrounding pair around a visual selection",
			},
		},
	},

	{
		"nvim-mini/mini.comment",
		opts = {
			options = {
				ignore_blank_line = true,
			},
		},
		keys = {
			{ "gcu", "gcgc", remap = true, desc = "Uncomment line" },
		},
	},

	-- Use nvim-autopairs because it works with abbreviations and allow for fast wrap
	{ "nvim-mini/mini.pairs", enabled = false },
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		opts = {
			enable_abbr = true,
			fast_wrap = {
				map = false, -- remap fastwrap manually below to hide Noice overlay
			},
		},
		keys = {
			{
				"<M-e>",
				"<Cmd>execute 'Noice dismiss' | lua require('nvim-autopairs.fastwrap').show()<CR>",
				mode = "i",
			},
		},
	},
}
