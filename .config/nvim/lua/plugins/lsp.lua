return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				["*"] = {
					keys = {
						-- Remove keymap to let <C-k> scroll documentation in Noice
						{ "<C-k>", false, mode = "i" },
					},
				},
				clangd = {
					init_options = {
						fallbackFlags = { "-std=c++23" },
					},
				},
				basedpyright = {
					settings = {
						basedpyright = {
							analysis = {
								diagnosticSeverityOverrides = {
									reportAny = false,
									reportAttributeAccessIssue = false,
									reportIgnoreCommentWithoutRule = false,
									reportMatchNotExhaustive = false,
									reportMissingParameterType = false,
									reportMissingTypeArgument = false,
									reportMissingTypeStubs = false,
									reportUnannotatedClassAttribute = false,
									reportUnknownArgumentType = false,
									reportUnknownMemberType = false,
									reportUnknownParameterType = false,
									reportUnknownVariableType = false,
									reportUnusedCallResult = false,
								},
							},
						},
					},
				},
			},
		},
	},
}
