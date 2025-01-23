--- Patch snacks' dashboard "Restore Session" action: by default, the action
--- is set to `require("persistence").load()`, which loads a session from
--- the current directory. We modify it to run a custom load function (that
--- we add to persistence) that tries to:
--- - load a session from the current directory
--- - fallbacks to last opened session if there is no session in the cwd

require("persistence").init_load = function()
	local M = require("persistence")
	local file

	file = M.current()
	if vim.fn.filereadable(file) == 0 then
		file = M.current({ branch = false })
	end
	if vim.fn.filereadable(file) == 0 then
		file = M.last()
	end
	if file and vim.fn.filereadable(file) ~= 0 then
		M.fire("LoadPre")
		vim.cmd("silent! source " .. vim.fn.fnameescape(file))
		M.fire("LoadPost")
	else
		vim.notify("No session to load")
	end
end

return {
	{
		"folke/snacks.nvim",
		config = function(_, opts)
			require("snacks").setup(opts)

			-- Overwrite button on dashboard to load sessions
			require("snacks.dashboard").sections.session = function(item)
				if require("snacks.dashboard").have_plugin("persistence.nvim") then
					return setmetatable({
						action = ":lua require('persistence').init_load()",
						section = false,
					}, { __index = item })
				end
			end
		end,
	},
}
