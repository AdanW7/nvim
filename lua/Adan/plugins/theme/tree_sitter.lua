local M = {}

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
    'https://github.com/nvim-treesitter/nvim-treesitter-context',
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  }, { load = true, confirm = false })

  require('Adan.overrides.treesitter')
end

return M
