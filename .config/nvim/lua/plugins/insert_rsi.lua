
local M = {
  "insert_rsi",
  name = "insert_rsi",

  dev = {true},
}

function M.config(_)
  vim.keymap.set("i", "<C-A>", "<C-O>^")
  vim.keymap.set("i", "<C-X><C-A>", "<C-A>")

  vim.keymap.set("i", "<C-B>", function()
    if vim.fn.col(".") == 1 then
      return "<C-O>k<C-O>$"
    else
      return "<Left>"
    end
  end, { expr = true })

  vim.keymap.set("i", "<C-D>", function()
    if vim.fn.col(".") > vim.fn.strlen(vim.fn.getline(".")) then
      return "<C-D>"
    else
      return "<Del>"
    end
  end, { expr = true })

  vim.keymap.set("i", "<C-E>", function()
    if vim.fn.col(".") > vim.fn.strlen(vim.fn.getline(".")) then
      return "<C-E>"
    else
      return "<End>"
    end
  end, { expr = true })

  vim.keymap.set("i", "<C-F>", function()
    if vim.fn.col(".") > vim.fn.strlen(vim.fn.getline(".")) then
      return "<C-F>"
    else
      return "<Right>"
    end
  end, { expr = true })

  vim.keymap.set("i", "<M-b>", "<S-Left>")
  vim.keymap.set("i", "<M-f>", "<S-Right>")
  vim.keymap.set("i", "<M-d>", "<C-o>dw")
  vim.keymap.set("i", "<M-BS>", "<C-W>")
  vim.keymap.set("i", "<M-C-h>", "<C-W>")
end

return M
