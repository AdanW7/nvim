local M = {}
function M.setup()
  vim.pack.add({
    { src = 'https://github.com/echasnovski/mini.nvim', version = 'stable' },
  }, { load = true, confirm = false })

  require('mini.ai').setup()
  require('mini.icons').setup()
  require('mini.icons').mock_nvim_web_devicons()
  require('mini.pairs').setup()

  vim.keymap.set('n', 's', '<Nop>', { noremap = true })
  require('mini.surround').setup({
    respect_selection_type = true,
  })
  require('mini.cursorword').setup({ delay = 100 })
  require('mini.jump').setup({
    mappings = {
      repeat_jump = '', -- disable repeat
    },
    delay = {
      idle_stop = 1, -- stop immediately after jump
    },
  })
end
return M
