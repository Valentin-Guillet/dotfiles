local function neotree_auto_close(cmd)
	return function(state)
		local node = state.tree:get_node()
		state.commands[cmd](state)
		if node.type == "file" then
			require("neo-tree.command").execute({ action = "close" })
		end
	end
end

local function neotree_navigate(get_dest_func)
	return function(state)
		local renderer = require("neo-tree.ui.renderer")
		renderer.focus_node(state, get_dest_func(state.tree))
	end
end

return {
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				mappings = {
					i = {
						["<M-j>"] = "preview_scrolling_left",
						["<M-k>"] = "preview_scrolling_right",
						["<C-j>"] = "results_scrolling_left",
						["<C-k>"] = "results_scrolling_right",
						["<M-f>"] = { "<S-Right>", type = "command" },
						["<C-u>"] = false,
					},
					n = {
						["<C-c>"] = "close",
						["v"] = "select_vertical",
						["\\"] = "select_vertical",
						["-"] = "select_horizontal",
					},
				},
			},
		},
	},

	{
		"nvim-neo-tree/neo-tree.nvim",
		opts = {
			close_if_last_window = true,
			filesystem = {
				filtered_items = {
					hide_gitignored = false,
				},
			},

			window = {
				mappings = {
					["s"] = false,

					-- Open file but keep focus in Neotree
					["l"] = {
						function(state)
							local node = state.tree:get_node()
							state.commands["open"](state)
							if node.type == "file" then
								require("neo-tree.command").execute({ action = "focus" })
							end
						end,
						desc = "Preview file",
					},

					-- Open file and close Neotree
					["<CR>"] = { neotree_auto_close("open"), desc = "Open & autoclose" },
					["\\"] = { neotree_auto_close("open_vsplit"), desc = "Open vsplit & autoclose" },
					["-"] = { neotree_auto_close("open_split"), desc = "Open split & autoclose" },

					["<C-v>"] = "open_vsplit",
					["<C-x>"] = "open_split",

					["]]"] = {
						neotree_navigate(function(tree)
							local siblings = tree:get_nodes(tree:get_node():get_parent_id())
							return siblings[#siblings]:get_id()
						end),
						desc = "Goto last sibling",
					},

					["[["] = {
						neotree_navigate(function(tree)
							local siblings = tree:get_nodes(tree:get_node():get_parent_id())
							return siblings[1]:get_id()
						end),
						desc = "Goto first sibling",
					},

					["]u"] = {
						neotree_navigate(function(tree)
							return tree:get_node():get_parent_id()
						end),
						desc = "Goto parent",
					},
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

				map("n", "]h", function()
					gs.nav_hunk("next")
				end, "Next Hunk")
				map("n", "[h", function()
					gs.nav_hunk("prev")
				end, "Prev Hunk")
				map("n", "]H", function()
					gs.nav_hunk("last")
				end, "Last Hunk")
				map("n", "[H", function()
					gs.nav_hunk("first")
				end, "First Hunk")
				map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Stage hunk")
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "Reset hunk")
				map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
				map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
				map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, "Blame Line")
				map("n", "<leader>hd", gs.diffthis, "Diff This")
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, "Diff This ~")
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

	{
		"debugloop/telescope-undo.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-telescope/telescope.nvim" },
		keys = {
			{ "<leader>su", "<cmd>Telescope undo<cr>", desc = "Undo history" },
		},
		config = function(_, opts)
			require("telescope").setup(opts)
			require("telescope").load_extension("undo")
		end,
	},

	"tpope/vim-sleuth",
}
