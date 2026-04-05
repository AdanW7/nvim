local M = {}

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/nvim-mini/mini.ai', version = 'stable' },
    { src = 'https://github.com/nvim-mini/mini.icons', version = 'stable' },
    { src = 'https://github.com/nvim-mini/mini.pairs', version = 'stable' },
    { src = 'https://github.com/nvim-mini/mini.comment', version = 'stable' },
    { src = 'https://github.com/nvim-mini/mini.surround', version = 'stable' },
    { src = 'https://github.com/nvim-mini/mini.cursorword', version = 'stable' },
  }, { load = true, confirm = false })

  require('mini.ai').setup()
  require('mini.icons').setup()
  require('mini.pairs').setup()
  require('mini.comment').setup()
  require('mini.surround').setup({
    respect_selection_type = true,
  })
  require('mini.cursorword').setup({ delay = 100 })
end

return M
