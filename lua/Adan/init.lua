require('Adan.core')

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    require('Adan.pack')
    require('Adan.autocommands')
    require('Adan.UserCommands')
  end,
})
