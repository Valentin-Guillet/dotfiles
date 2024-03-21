return {
	{
		"nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>fE",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = Util.root() })
        end,
        desc = "Explorer NeoTree (root dir)",
      },
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
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

  -- { "folke/which-key.nvim", enabled = false, },
  {
    "folke/which-key.nvim",
    opts = {
      defaults = {
        ["<leader>m"] = { name = "sessions" },
      },
    },
  },

	{
		"lewis6991/gitsigns.nvim",
    opts = {
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

        -- Register at least one mapping using which-key to properly setup
        -- the group name (there's a bug otherwise)
        local wk = require("which-key")
        wk.register({
          ["<leader>h"] = {
            name = "hunks",
            mode = { "n", "v" },
            s = { ":Gitsigns stage_hunk<CR>", "Stage Hunk"},
            r = { ":Gitsigns reset_hunk<CR>", "Reset Hunk"},
          },
        })

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

        -- stylua: ignore start
        map("n", "]h", gs.next_hunk, "Next Hunk")
        map("n", "[h", gs.prev_hunk, "Prev Hunk")
        -- map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        -- map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>hS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>hd", gs.diffthis, "Diff This")
        map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
			end,
		},
	},
}
