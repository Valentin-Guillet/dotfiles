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
				{ "<leader>m", group = "quit/session" },
			},
		},
		config = function(_, opts)
			require("which-key").setup(opts)

			-- Overwrite getchar function so that <C-c> acts as <Esc> and cancel
			-- which-key as well as current action (e.g. using c- or d- operator)
			require("which-key.state").getchar = function()
				local status, char = pcall(vim.fn.getcharstr)
				if not status and char == "Keyboard interrupt" then
					return true, ""
				end
				return status, char
			end
		end,
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

	{ "tpope/vim-sleuth", event = "VeryLazy" },

	{
		"mrjones2014/smart-splits.nvim",
		keys = {
			{ "<M-h>", function() require("smart-splits").move_cursor_left() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-j>", function() require("smart-splits").move_cursor_down() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-k>", function() require("smart-splits").move_cursor_up() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-l>", function() require("smart-splits").move_cursor_right() end, mode = { "n", "i", "v", "o", "t" }, },

			{ "<M-H>", function() require("smart-splits").resize_left() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-J>", function() require("smart-splits").resize_down() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-K>", function() require("smart-splits").resize_up() end, mode = { "n", "i", "v", "o", "t" }, },
			{ "<M-L>", function() require("smart-splits").resize_right() end, mode = { "n", "i", "v", "o", "t" }, },
		},
	},
}
