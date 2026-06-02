local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/nvim-lua/plenary.nvim',
  }, { load = true, confirm = false })

  require('Adan.overrides.telescope')
end

return M
