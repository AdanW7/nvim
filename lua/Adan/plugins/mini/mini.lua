return {
  {
    'nvim-mini/mini.ai',
    version = '*',
    config = function()
      require('mini.ai').setup()
    end,
  },
  {
    'nvim-mini/mini.icons',
    version = '*',
    config = function()
      require('mini.icons').setup()
    end,
  },
  {
    'nvim-mini/mini.pairs',
    version = '*',
    config = function()
      require('mini.pairs').setup()
    end,
  },
  {
    'nvim-mini/mini.comment',
    version = '*',
    config = function()
      require('mini.comment').setup()
    end,
  },
  {
    'nvim-mini/mini.surround',
    version = '*',
    config = function()
      require('mini.surround').setup({
        respect_selection_type = true,
      })
    end,
  },
  {
    'nvim-mini/mini.cursorword',
    version = '*',
    config = function()
      require('mini.cursorword').setup({ delay = 100 })
    end,
  },
}
