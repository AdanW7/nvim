local M = {}
function M.setup()
  local function setup_lsp()
    require('Adan.lsp').setup()
  end

  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = setup_lsp,
  })

  if vim.api.nvim_buf_get_name(0) ~= '' then
    setup_lsp()
  end
end
return M
