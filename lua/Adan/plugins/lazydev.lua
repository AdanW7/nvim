local M = {}
function M.setup()
  local function setup_lazydev()
    if package.loaded['lazydev'] then
      return
    end

    vim.pack.add({
      'https://github.com/folke/lazydev.nvim',
    }, { load = true, confirm = false })

    require('lazydev').setup {
      enabled = true,
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
        { path = 'mini.nvim', words = { 'Mini' } },
      },
    }
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'lua',
    once = true,
    callback = setup_lazydev,
  })

  if vim.bo.filetype == 'lua' then
    setup_lazydev()
  end
end
return M
