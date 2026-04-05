local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/tiagovla/scope.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
  }, { load = true, confirm = false })

  require('scope').setup({
    hooks = {
      pre_tab_enter = function() end,
      post_tab_enter = function() end,
      pre_tab_leave = function() end,
      post_tab_leave = function() end,
      pre_tab_close = function() end,
      post_tab_close = function() end,
    },
  })

  vim.keymap.set('n', '<leader>fB', '<cmd>Telescope scope buffers<cr>', {
    desc = 'All buffers (all tabs)',
  })
  vim.keymap.set('n', '<leader>tmb', '<cmd>ScopeMoveBuf<cr>', {
    desc = 'Move buffer to a specific tab',
  })
end

return M
