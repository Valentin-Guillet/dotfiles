return {
	{
		"hrsh7th/nvim-cmp",

		opts = function(_, opts)
			local cmp = require("cmp")
			local neocodeium = require("neocodeium")
			opts.mapping = vim.tbl_extend("force", opts.mapping, {
				["<C-B>"] = cmp.config.disable,
				["<C-F>"] = cmp.config.disable,
				["<C-K>"] = cmp.mapping.scroll_docs(-4),
				["<C-J>"] = cmp.mapping.scroll_docs(4),
				["<Tab>"] = cmp.mapping({
					i = function(fallback)
						if neocodeium.visible() then
							neocodeium.accept()
						elseif cmp.visible() then
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
						else -- send "<Tab>" through
							fallback()
						end
					end,
				}),
			})
		end,
	},

	{
		"monkoose/neocodeium",
		event = "VeryLazy",
		config = function()
			local neocodeium = require("neocodeium")
			neocodeium.setup({ manual = true })

			-- create an autocommand which closes cmp when ai completions are displayed
			vim.api.nvim_create_autocmd("User", {
				pattern = "NeoCodeiumCompletionDisplayed",
				callback = function()
					require("cmp").abort()
				end,
			})

			vim.keymap.set("i", "<M-Space>", neocodeium.accept)
			vim.keymap.set("i", "<M-]>", function() neocodeium.cycle_or_complete(1) end)
			vim.keymap.set("i", "<M-[>", function() neocodeium.cycle_or_complete(-1) end)
		end,
	},

	{
		"echasnovski/mini.surround",
		opts = {
			mappings = {
				add = "ys",
				delete = "ds",
				find = "",
				find_left = "",
				highlight = "",
				replace = "cs",
				update_n_lines = "",
			},
		},
	},

	{
		"echasnovski/mini.comment",
		opts = {
			options = {
				ignore_blank_line = true,
			},
		},
	},

	{ "echasnovski/mini.pairs", enabled = false, },
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
		opts = {
			enable_abbr = true,
			fast_wrap = {},
		},
	},
}
