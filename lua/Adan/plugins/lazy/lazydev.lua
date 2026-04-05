local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/folke/lazydev.nvim' }, { load = true, confirm = false })

  require('lazydev').setup({
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      { path = 'render-markdown.nvim', words = { 'render%-markdown' } },
    },
  })
end

return M
