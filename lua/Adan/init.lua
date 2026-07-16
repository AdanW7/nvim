require('Adan.core')
require('Adan.autocommands')
require('Adan.UserCommands')

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    require('Adan.pack')
  end,
})
