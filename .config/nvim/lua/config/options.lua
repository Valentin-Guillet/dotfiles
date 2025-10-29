vim.opt.scrolloff = 3
vim.opt.sidescrolloff = 5

vim.opt.gdefault = true

vim.opt.clipboard = ""

vim.opt.diffopt = "internal,filler,closeoff,algorithm:histogram,indent-heuristic,linematch:60"

vim.g.autoformat = false

vim.g.snacks_animate = false

-- By default, when searching for the root directory, LazyVim finds "$HOME/.git", but most of
-- the time we don't want to take it into account so we ignore it here
---@param patterns string[]|string
local function no_home_git_pattern_search(buf, patterns)
	local pattern = require("lazyvim.util.root").detectors.pattern(buf, patterns)
	return pattern[1] == vim.fn.expand("~") and {} or pattern
end

vim.g.root_spec = {
	"lsp",
	function(buf)
		return no_home_git_pattern_search(buf, { ".git", "lua" })
	end,
	"cwd",
}
