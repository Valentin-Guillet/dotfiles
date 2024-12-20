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
		"kylechui/nvim-surround",
		event = "VeryLazy",
		opts = {},
	},

	{
		"echasnovski/mini.comment",
		opts = {
			options = {
				ignore_blank_line = true,
			},
		},
		config = function(_, opts)
			require("mini.comment").setup(opts)

			function CommentAndDuplicate(mode)
				local start_line, end_line
				local curr_pos

				if mode == "v" or mode == "V" then
					curr_pos = vim.fn.getpos("'<")
					start_line = curr_pos[2]
					end_line = vim.fn.getpos("'>")[2]
				else
					start_line = vim.fn.getpos("'[")[2]
					end_line = vim.fn.getpos("']")[2]
					curr_pos = vim.b.CAD_pos
					vim.b.CAD_pos = nil
				end
				local lines = vim.fn.getline(start_line, end_line)

				require("mini.comment").toggle_lines(start_line, end_line)
				vim.fn.append(end_line, lines)
				vim.fn.setpos('.', { 0, end_line + 1 + curr_pos[2] - start_line, curr_pos[3], 0 })
			end

			vim.keymap.set('x', 'gs', ':<C-u>lua CommentAndDuplicate(vim.fn.visualmode())<CR>', { silent = true })
			vim.keymap.set('n', 'gs', '<CMD>let b:CAD_pos = getpos(".") | set operatorfunc=v:lua.CommentAndDuplicate<CR>g@', { silent = true })
			vim.keymap.set('n', 'gss', 'gsl', { remap = true, silent = true })
		end
	},

	-- Use nvim-autopairs because it works with abbreviations and allow for fast wrap
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
