local M = {}
function M.setup()
  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = function()
      require('Adan.lsp').setup()
    end,
  })
end
return M
