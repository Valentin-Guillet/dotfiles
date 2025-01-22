return {
	{
		"folke/persistence.nvim",
		keys = {
			{ "<leader>qs", false },
			{ "<leader>qS", false },
			{ "<leader>ql", false },
			{ "<leader>qd", false },
			{ "<leader>ms", function() require("persistence").load() end, desc = "Restore session", },
			{ "<leader>mS", function() require("persistence").select() end, desc = "Select session", },
			{ "<leader>ml", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session", },
			{ "<leader>md", function() require("persistence").stop() end, desc = "Don't Save Current Session on Exit", },
		},
	},

	{
		"ahmedkhalf/project.nvim",
		opts = {
			manual_mode = false,
		},

		-- When manual_mode = false in the default plugin,
		-- + cwd is automatically changed when entering a project
		-- + detected projects are automatically added to project history
		-- Here, we modify a plugin function so that the first behavior is
		-- kept (autochdir), but projects are added to history only when
		-- calling it manually (i.e. via `:AddProject`)
		config = function(_, opts)
			local plugin = require("project_nvim")
			local config = require("project_nvim.config")
			local history = require("project_nvim.utils.history")

			plugin.setup(opts)
			require("project_nvim.project").set_pwd = function(dir, method)
				if dir == nil then
					return false
				end

				if method == "manual" then
					plugin.last_project = dir
					table.insert(history.session_projects, dir)
				end

				if vim.fn.getcwd() == dir then
					return true
				end

				local scope_chdir = config.options.scope_chdir
				if scope_chdir == 'global' then
					vim.api.nvim_set_current_dir(dir)
				elseif scope_chdir == 'tab' then
					vim.cmd('tcd ' .. dir)
				elseif scope_chdir == 'win' then
					vim.cmd('lcd ' .. dir)
				else
					return
				end

				if config.options.silent_chdir == false then
					vim.notify("Set CWD to " .. dir .. " using " .. method)
				end
				return true
			end
		end,
	},
}
