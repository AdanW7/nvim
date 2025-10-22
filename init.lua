vim.opt.runtimepath:prepend(vim.fn.stdpath('config') .. '/helix.nvim')

require('Adan')

-- =============================================================================
-- enable ui2 mode
-- =============================================================================
require('vim._core.ui2').enable()

vim.filetype.add({
  extension = {
    tmx = 'toml',
  },
})
