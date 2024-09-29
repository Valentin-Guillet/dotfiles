return {
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				mappings = {
					i = {
						["<M-j>"] = "results_scrolling_left",
						["<M-f>"] = { "<S-Right>", type = "command" },
						["<C-u>"] = false,
					},
					n = {
						["<C-c>"] = "close",
						["v"] = "select_vertical",
					},
				},
			},
		},
	},

	{
		"nvim-neo-tree/neo-tree.nvim",
		keys = {
			{
				"<leader>fE",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
				end,
				desc = "Explorer NeoTree (root dir)",
			},
			{
				"<leader>fe",
				function()
					require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
				end,
				desc = "Explorer NeoTree (cwd)",
			},
			{ "<leader>E", "<leader>fE", desc = "Explorer NeoTree (root dir)", remap = true },
			{ "<leader>e", "<leader>fe", desc = "Explorer NeoTree (cwd)", remap = true },
		},
		opts = {
			filesystem = {
				filtered_items = {
					hide_gitignored = false,
				},
			},
			window = {
				mappings = {
					["Y"] = "none",
				},
			},
		},
	},

	{ "folke/flash.nvim", enabled = false },

	{
		"folke/which-key.nvim",
		opts = {
			spec = {
				-- Cf. persistence plugin defined in util.lua
				-- Must be defined here because the plugin is lazy-loaded
				{ "<leader>m", group = "sessions" },
			},
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

				local wk = require("which-key")
				wk.add({
					{
						"<leader>h",
						group = "hunks",
						icon = { icon = "󰊢", color = "orange" },
						mode = { "n", "v" },
					},
				})

				map("n", "]h", function() gs.nav_hunk("next") end, "Next Hunk")
				map("n", "[h", function() gs.nav_hunk("prev") end, "Prev Hunk")
				map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
				map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
				map("v", "<leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
				map("v", "<leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
				map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
				map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
				map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
				map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
				map("n", "<leader>hd", gs.diffthis, "Diff This")
				map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
				map("n", "<leader>ht", gs.toggle_deleted)
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
			end,
		},
	},

	{
		"echasnovski/mini.move",
		opts = {
			mappings = {
				left = "|",
				right = "\\",
				down = "-",
				up = "_",

				line_left = "",
				line_right = "",
				line_down = "-",
				line_up = "_",
			},
		},
	},
}
