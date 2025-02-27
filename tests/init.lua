vim.cmd([[set runtimepath+=.]])
vim.cmd([[runtime! plugin/plenary.vim]])
vim.cmd([[runtime! plugin/nvim-treesitter.vim]])

vim.o.swapfile = false
vim.bo.swapfile = false
vim.g.aerial = {
  filter_kind = false,
}

require("nvim-treesitter.configs").setup({
  ensure_installed = "maintained",
})
