local function uv_get_editable_pkgs()
	local handle = io.popen("uv pip list --editable --format json -q")
	if not handle then
		vim.notify("Failed to execute 'uv'", vim.log.ERROR)
		return {}
	end

	local output = handle:read("*a")
	handle:close()

	if not output or output:len() == 0 then
		return {}
	end

	local success, result = pcall(vim.json.decode, output)
	if not success then
		vim.notify("Failed to decode JSON output from 'uv' cmd: " .. result, vim.log.ERROR)
		return {}
	end

	local paths = {}
	for _, pkg in ipairs(result) do
		table.insert(paths, pkg.editable_project_location)
	end

	return paths
end

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        settings = {
          python = {
            analysis = {
              extraPaths = uv_get_editable_pkgs(),
            },
          },
        },
      },
    },
  },
}
