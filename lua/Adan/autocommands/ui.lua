local group = vim.api.nvim_create_augroup('AdanUiAutocmds', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ timeout = 170 })
  end,
  desc = 'Highlight yanked text',
})
