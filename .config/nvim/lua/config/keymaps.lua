-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Delete default lazy mappings

vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")

vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

vim.keymap.del({ "n", "i", "v" }, "<M-j>")
vim.keymap.del({ "n", "i", "v" }, "<M-k>")

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

-- Alt-u to undo in insert mode
vim.keymap.set("i", "<M-u>", "<C-O>u")

-- Scroll
vim.keymap.set("n", "<C-j>", function()
	if not require("noice.lsp").scroll(2) then
		return "<C-e>"
	end
end, { silent = true, expr = true, desc = "Scroll down" })

vim.keymap.set("n", "<C-k>", function()
	if not require("noice.lsp").scroll(-2) then
		return "<C-y>"
	end
end, { silent = true, expr = true, desc = "Scroll up" })

-- Move to window using the <alt> hjkl keys
vim.keymap.set("n", "<M-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<M-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<M-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<M-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize window using <alt> HJKL
vim.keymap.set("n", "<M-K>", "<CMD>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("n", "<M-J>", "<CMD>resize -2<cr>", { desc = "Decrease window height" })
vim.keymap.set("n", "<M-H>", "<CMD>vertical resize -2<cr>", { desc = "Decrease window width" })
vim.keymap.set("n", "<M-L>", "<CMD>vertical resize +2<cr>", { desc = "Increase window width" })

-- buffers
vim.keymap.set("n", "<C-l>", "<CMD>noh<cr>", { desc = "Clear hlsearch" })

vim.keymap.set("n", "<leader>w", "<CMD>update<CR>", { desc = "Update" })
vim.keymap.set("n", "<leader>q", "<CMD>quit<CR>", { desc = "Quit" })

vim.keymap.set("n", "<M-\\>", "<CMD>vsplit<CR>", { silent = true })
vim.keymap.set("n", "<M-|>", "<CMD>vsplit | enew<CR>", { silent = true })
vim.keymap.set("n", "<M-->", "<CMD>split<CR>", { silent = true })
vim.keymap.set("n", "<M-_>", "<CMD>split | enew<CR>", { silent = true })
vim.keymap.set("n", "<M-=>", "<C-w>=", { silent = true })

vim.keymap.set("n", "<leader>\\", "<CMD>vsplit<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>|", "<CMD>vsplit | enew<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>-", "<CMD>split<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>_", "<CMD>split | enew<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "which_key_ignore", silent = true })

vim.keymap.set("n", "<leader>t", "<CMD>tab split<CR>", { desc = "which_key_ignore", silent = true })
vim.keymap.set("n", "<leader>T", "<CMD>tabnew<CR>", { desc = "which_key_ignore", silent = true })

vim.keymap.set("n", "<M-p>", "gT")
vim.keymap.set("n", "<M-n>", "gt")

vim.keymap.set("n", "<M-R>", "<CMD>tab split<CR>", { silent = true })
vim.keymap.set("n", "<M-T>", "<CMD>tabnew<CR>", { silent = true })

vim.keymap.set("n", "<M-P>", function()
	vim.cmd("tabmove " .. ((vim.fn.tabpagenr("$") + vim.fn.tabpagenr() - 1) % (vim.fn.tabpagenr("$") + 1)))
end)
vim.keymap.set("n", "<M-N>", function()
	vim.cmd("tabmove " .. ((vim.fn.tabpagenr() + 1) % (vim.fn.tabpagenr("$") + 1)))
end)

vim.keymap.set("n", "<M-<>", "<C-w>r")
vim.keymap.set("n", "<M->>", "<C-w>R")

vim.keymap.set("n", "<M-w>", "<C-w>c")
vim.keymap.set("n", "<M-W>", "<CMD>tabclose<CR>")
vim.keymap.set("n", "<leader>!", "<C-w>T", { desc = "Send to new tab" })

vim.keymap.set("n", "<leader>H", "<C-w>H", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>J", "<C-w>J", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>K", "<C-w>K", { desc = "which_key_ignore" })
vim.keymap.set("n", "<leader>L", "<C-w>L", { desc = "which_key_ignore" })

vim.keymap.set("v", "q", "<C-c>")

vim.keymap.set("n", "<C-h>", "o<C-c>")

-- Delete mark
vim.keymap.set("n", "dm", "<CMD>execute 'delmarks ' . nr2char(getchar())<CR>", { desc = "Delete mark" })

-- Swap words
vim.keymap.set("n", "gt", "<CMD>NeoSwapNext<CR>", { desc = "Swap next word", silent = true })
vim.keymap.set("n", "gT", "<CMD>NeoSwapPrev<CR>", { desc = "Swap prev word", silent = true })

-- In command line, <C-P> and <C-N> act as <Up> and <Down> (i.e. search in history)
vim.keymap.set("c", "<C-S-p>", "<Up>")
vim.keymap.set("c", "<C-S-n>", "<Down>")

-- Terminal movements
vim.keymap.set("t", "<M-h>", "<CMD>wincmd h<cr>", { desc = "Go to left window" })
vim.keymap.set("t", "<M-j>", "<CMD>wincmd j<cr>", { desc = "Go to lower window" })
vim.keymap.set("t", "<M-k>", "<CMD>wincmd k<cr>", { desc = "Go to upper window" })
vim.keymap.set("t", "<M-l>", "<CMD>wincmd l<cr>", { desc = "Go to right window" })

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
