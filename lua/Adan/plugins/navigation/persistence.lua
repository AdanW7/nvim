return {
  'folke/persistence.nvim',
  event = 'BufReadPre',
  opts = {},
  keys = {
    {
      '<leader>ss',
      function()
        require('persistence').load()
      end,
      desc = 'Restore Session for the Current Directory',
    },
    {
      '<leader>sS',
      function()
        require('persistence').select()
      end,
      desc = 'Select a Session to Load',
    },
    {
      '<leader>sl',
      function()
        require('persistence').load({ last = true })
      end,
      desc = 'Restore Last Session',
    },
    {
      '<leader>sd',
      function()
        require('persistence').stop()
      end,
      desc = "Don't Save Current Session",
    },
  },
}
