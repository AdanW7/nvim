local M = {}
function M.setup()
  vim.pack.add({
    'https://github.com/mason-org/mason.nvim',
  }, { load = true, confirm = false })

  require('mason').setup()

  local registry = require('mason-registry')
  registry.refresh(function()
    registry:on('package:install:success', function()
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds('FileType', {
          buffer = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)
  end)

  require('Adan.lsp').setup()
  vim.keymap.set('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })
end
return M
