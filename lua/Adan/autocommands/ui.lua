local group = vim.api.nvim_create_augroup('AdanUiAutocmds', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ higroup = 'YankHighlight', timeout = 170 })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype == '' then
      pcall(vim.treesitter.start, args.buf)
    end
  end,
})
