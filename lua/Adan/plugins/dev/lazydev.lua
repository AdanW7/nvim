local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/folke/lazydev.nvim',
  }, { load = false, confirm = false })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'lua',
    callback = function(args)
      local ok, lazydev = pcall(require, 'lazydev')
      if not ok then
        return
      end

      local root = vim.fs.root(args.buf, { '.luarc.json', '.git' }) or vim.fn.getcwd()
      local disabled_by_luarc = vim.uv.fs_stat(root .. '/.luarc.json') ~= nil
      local globally_enabled = vim.g.lazydev_enabled == nil or vim.g.lazydev_enabled

      if disabled_by_luarc or not globally_enabled then
        return
      end

      lazydev.setup({
        library = {
          'lazy.nvim',
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      })
    end,
    once = true,
  })
end

return M
