
return {
  {
    "hrsh7th/nvim-cmp",

    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<C-B>"] = cmp.config.disable,
        ["<C-F>"] = cmp.config.disable,
        ["<C-K>"] = cmp.mapping.scroll_docs(-4),
        ["<C-J>"] = cmp.mapping.scroll_docs(4),
      })
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
}
