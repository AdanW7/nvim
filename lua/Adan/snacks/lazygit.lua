return {
  'snacks.nvim',
  opts = {
    lazygit = {
      enabled = true,
      configure = true,
      theme = {
        -- Customize lazygit theme to match your colorscheme
        [241] = { fg = 'Special' },
        activeBorderColor = { fg = 'MatchParen', bold = true },
        inactiveBorderColor = { fg = 'FloatBorder' },
        searchingActiveBorderColor = { fg = 'MatchParen', bold = true },
        selectedLineBgColor = { bg = 'Visual' },
      },
    },
  },
  keys = {
    {
      '<leader>gg',
      function()
        Snacks.lazygit()
      end,
      desc = 'LazyGit',
    },
    {
      '<leader>gG',
      function()
        Snacks.lazygit.log()
      end,
      desc = 'LazyGit Log',
    },
    {
      '<leader>gbh',
      function()
        Snacks.lazygit.log_file()
      end,
      desc = 'LazyGit Current File History',
    },
  },
}
