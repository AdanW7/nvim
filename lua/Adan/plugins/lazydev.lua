local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/folke/lazydev.nvim',
  }, { load = true, confirm = false })

  require('lazydev').setup({
    enabled = true,
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'snacks.nvim', words = { 'Snacks' } },
      { path = 'mini.nvim', words = { 'Mini' } },
    },
  })
end

return M
