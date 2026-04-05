local M = {}

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/L3MON4D3/LuaSnip', version = 'master' },
    'https://github.com/rafamadriz/friendly-snippets',
  }, { load = true, confirm = false })

  require('luasnip.loaders.from_vscode').lazy_load()
end

return M
