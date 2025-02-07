return {
	-- Both nvim-lint and conform set default SQL dialect to ANSI,
	-- so we remove it from arguments
	-- NB: there must be a `.sqlfluff` file in the root of the project
	-- to make linting and formatting work
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters = {
				sqlfluff = {
					args = { "lint", "--format=json" },
				},
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters = {
				sqlfluff = {
					args = { "format", "-" },
				},
			},
		},
	},
}
