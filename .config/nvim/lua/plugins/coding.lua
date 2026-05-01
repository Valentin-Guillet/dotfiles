return {
	{
		"saghen/blink.cmp",
		opts = {
			keymap = {
				-- Documentation scrolling is managed by `noice`
				["<C-b>"] = { "fallback" },
				["<C-f>"] = { "fallback" },
				["<C-e>"] = { -- Prevent Blink from intercepting <C-e> from local plugin `insert_rsi`
					function(cmp)
						cmp.accept()
						return false
					end,
					"fallback",
				},

				["<Tab>"] = {
					function(cmp)
						if require("neocodeium").visible() then
							require("neocodeium").accept()
							return true
						elseif cmp.snippet_active() then
							return cmp.accept()
						else
							return cmp.select_and_accept()
						end
					end,
					"snippet_forward",
					"fallback",
				},
			},
		},
	},

	{
		"monkoose/neocodeium",
		event = "VeryLazy",
		config = function()
			local neocodeium = require("neocodeium")
			neocodeium.setup({ manual = true })

			vim.keymap.set("i", "<M-Space>", function() neocodeium.accept() end, { silent = true })
			vim.keymap.set("i", "<M-}>", function() neocodeium.cycle_or_complete(1) end, { silent = true })
			vim.keymap.set("i", "<M-{>", function() neocodeium.cycle_or_complete(-1) end, { silent = true })

			-- create an autocommand which closes blink when ai completions are displayed
			vim.api.nvim_create_autocmd("User", {
				pattern = "NeoCodeiumCompletionDisplayed",
				callback = function()
					require("blink-cmp").cancel()
				end,
			})
		end,
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
