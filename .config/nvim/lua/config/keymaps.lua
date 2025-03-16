-- Delete default lazy mappings

vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")

vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

vim.keymap.del("n", "<S-h>")
vim.keymap.del("n", "<S-l>")
vim.keymap.del("n", "<leader>bb")
vim.keymap.del("n", "<leader>`")

vim.keymap.del("n", "<leader>ur")
vim.keymap.del("n", "<leader>K")
vim.keymap.del("n", "<leader>l")
vim.keymap.del("n", "<leader>L")

vim.keymap.del("n", "<leader>wd")
vim.keymap.del("n", "<leader>|")

vim.keymap.del("n", "<leader>qq")

vim.keymap.del("n", "<c-_>")
vim.keymap.del("t", "<c-_>")

vim.keymap.del({ "n", "x", "s" }, "<C-s>")

-- Set own mappings

-- Exit insert mode
vim.keymap.set("i", "kj", "<Esc>l")
vim.keymap.set("i", "Kj", "<Esc>l")
vim.keymap.set("i", "kJ", "<Esc>l")
vim.keymap.set("i", "KJ", "<Esc>l")
-- <C-c> doesn't trigger InsertLeave by default, and we need it to toggle diagnostics in insert mode
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Redefine default mapping because it can't be pressed fast otherwise for some reason
vim.keymap.set("n", "<leader>wd", function() vim.diagnostic.open_float() end, { desc = "Update" })

-- Alt-u to undo in insert mode
vim.keymap.set("i", "<M-u>", "<C-O>u")

-- Scroll
vim.keymap.set({ "n", "v" }, "<C-j>", function() if not require("noice.lsp").scroll(2) then return "<C-e>" end end, { silent = true, expr = true, desc = "Scroll down" })
vim.keymap.set({ "n", "v" }, "<C-k>", function() if not require("noice.lsp").scroll(-2) then return "<C-y>" end end, { silent = true, expr = true, desc = "Scroll up" })
vim.keymap.set("i", "<C-j>", function() if not require("noice.lsp").scroll(2) then return "<C-O><C-e>" end end, { silent = true, expr = true, desc = "Scroll down" })
vim.keymap.set("i", "<C-k>", function() if not require("noice.lsp").scroll(-2) then return "<C-o><C-y>" end end, { silent = true, expr = true, desc = "Scroll up" })

-- buffers
vim.keymap.set("n", "<leader>ww", "<Cmd>update<CR>", { desc = "Update" })
vim.keymap.set("n", "<leader>q", "<Cmd>quit<CR>", { desc = "Quit" })

vim.keymap.set("n", "<M-\\>", "<Cmd>vsplit<CR>", { silent = true })
vim.keymap.set("n", "<M-|>", "<Cmd>vsplit | enew<CR>", { silent = true })
vim.keymap.set("n", "<M-->", "<Cmd>split<CR>", { silent = true })
vim.keymap.set("n", "<M-_>", "<Cmd>split | enew<CR>", { silent = true })
vim.keymap.set("n", "<M-=>", "<C-w>=", { silent = true })

vim.keymap.set("n", "<leader>\\", "<Cmd>vsplit<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>|", "<Cmd>vsplit | enew<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>-", "<Cmd>split<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>_", "<Cmd>split | enew<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "which_key_ignore", silent = true })

vim.keymap.set("n", "<leader>t", "<Cmd>tab split<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>T", "<Cmd>tabnew<CR>", { desc = "which_key_ignore", silent = true })

vim.keymap.set("n", "[<Tab>", "gT")
vim.keymap.set("n", "]<Tab>", "gt")

vim.keymap.set("n", "<M-R>", "<Cmd>tab split<CR>", { silent = true })
vim.keymap.set("n", "<M-T>", "<Cmd>tabnew<CR>", { silent = true })

vim.keymap.set("n", "<M-P>", function()
	vim.cmd("tabmove " .. ((vim.fn.tabpagenr("$") + vim.fn.tabpagenr() - 1) % (vim.fn.tabpagenr("$") + 1)))
end)
vim.keymap.set("n", "<M-N>", function()
	vim.cmd("tabmove " .. ((vim.fn.tabpagenr() + 1) % (vim.fn.tabpagenr("$") + 1)))
end)

vim.keymap.set("n", "<M-<>", "<C-w>r")
vim.keymap.set("n", "<M->>", "<C-w>R")

vim.keymap.set("n", "<M-w>", "<C-w>c")
vim.keymap.set("n", "<M-W>", "<Cmd>tabclose<CR>")
vim.keymap.set("n", "<leader>!", "<C-w>T", { desc = "Send to new tab" })

vim.keymap.set("n", "<leader>H", "<C-w>H", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>J", "<C-w>J", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>K", "<C-w>K", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>L", "<C-w>L", { desc = "which_key_ignore" })

vim.keymap.set("v", "q", "<C-c>")

vim.keymap.set("n", "<C-h>", "<Cmd>put=''<CR>")

-- Swap words
vim.keymap.set("n", "gt", function()
	vim.cmd('normal "_yiw')
	vim.cmd([[keeppattern s/\v(%#\w+)(\_W+)(\w+)/\3\2\1/ | normal! ``]])
	vim.fn.search([[\w\+\_W\+]])
end, { desc = "Swap next word", silent = true })
vim.keymap.set("n", "gT", function()
	vim.cmd('normal "_yiw')
	vim.fn.search([[\w\+\_W\+]], "b")
	vim.cmd([[keeppattern s/\v(%#\w+)(\_W+)(\w+)/\3\2\1/ | normal! ``]])
end, { desc = "Swap next word", silent = true })

-- In command line, <C-P> and <C-N> act as <Up> and <Down> (i.e. search in history)
vim.keymap.set("c", "<C-S-p>", "<Up>")
vim.keymap.set("c", "<C-S-n>", "<Down>")

-- Terminal movements
vim.keymap.set("t", "<M-h>", "<Cmd>wincmd h<CR>", { desc = "Go to left window" })
vim.keymap.set("t", "<M-j>", "<Cmd>wincmd j<CR>", { desc = "Go to lower window" })
vim.keymap.set("t", "<M-k>", "<Cmd>wincmd k<CR>", { desc = "Go to upper window" })
vim.keymap.set("t", "<M-l>", "<Cmd>wincmd l<CR>", { desc = "Go to right window" })

-- Help abbreviations
vim.cmd([[cnoreabbrev <expr> h ((getcmdtype() == ':' && getcmdpos() <= 2)? 'vert h' : 'h')]])
vim.cmd([[cnoreabbrev <expr> help ((getcmdtype() == ':' && getcmdpos() <= 5)? 'vert help' : 'help')]])
vim.cmd([[cnoreabbrev <expr> H ((getcmdtype() == ':' && getcmdpos() <= 2)? 'tab h' : 'H')]])
vim.cmd([[cnoreabbrev <expr> Help ((getcmdtype() == ':' && getcmdpos() <= 5)? 'tab help' : 'Help')]])

-- <C-V> to copy in insert mode and in command line
vim.keymap.set({ "i", "c" }, "<C-S-v>", "<C-R>+", { desc = "Paste from clipboard" })

-- Open autocomplete on next subdirectory in command line
vim.keymap.set("c", "<C-o>", "<Space><BS><C-z>", { desc = "Autocomplete in next subdirectory" })


-- Neovide mappings
vim.g.neovide_hide_mouse_when_typing = false

vim.g.neovide_scale_factor = 1.0
vim.keymap.set("n", "<C-+>", function()
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.08
	vim.cmd("redraw!")
end, { desc = "Zoom in" })
vim.keymap.set("n", "<C-->", function()
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.08
	vim.cmd("redraw!")
end, { desc = "Zoom out" })
