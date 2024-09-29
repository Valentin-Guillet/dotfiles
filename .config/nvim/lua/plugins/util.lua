return {
	{
		"folke/persistence.nvim",
		keys = function(_, _)
			return {
				{ "<leader>ms", function() require("persistence").load() end, desc = "Restore session", },
				{ "<leader>mS", function() require("persistence").select() end, desc = "Select session", },
				{ "<leader>ml", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session", },
				{ "<leader>md", function() require("persistence").stop() end, desc = "Don't Save Current Session", },
			}
		end,
	},
}
