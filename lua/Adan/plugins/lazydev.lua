local M = {}
function M.setup()
  vim.pack.add({
    'https://github.com/folke/lazydev.nvim',
  }, { load = false, confirm = false })

  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = function()
      require('lazydev').setup {
        enabled = true,
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          { path = 'snacks.nvim', words = { 'Snacks' } },
          { path = 'mini.nvim', words = { 'Mini' } },
        },
      }
    end,
  })
end
return M
