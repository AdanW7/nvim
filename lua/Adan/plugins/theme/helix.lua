local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/AdanW7/helix.nvim' }, { load = true, confirm = false })

  require('helix').setup({
    transparent = false,
    term_colors = true,
    ending_tildes = false,
    code_style = {
      comments = 'italic',
      keywords = 'none',
      functions = 'none',
      strings = 'none',
      variables = 'none',
      constants = 'none',
    },
    diagnostics = {
      darker = false,
      undercurl = true,
      background = false,
    },
    colors = {},
    highlights = {
      SnacksIndent = { fg = '#5f79a6' },
      SnacksIndentScope = { fg = '#7394cf', fmt = 'bold' },
      ColorfulMenuFallback = { fg = '#89b4fa', fmt = 'bold' },
      ColorfulMenuDim = { fg = '#6c7d9b' },
      ColorfulMenuArgs = { fg = '#e0b97f' },
      DiffAdd = { bg = '#2d4432' },
      DiffChange = { bg = '#344353' },
      DiffDelete = { bg = '#433234' },
      DiffText = { bg = '#385070' },
      DiffviewDiffAdd = { bg = '#2d4432' },
      DiffviewDiffChange = { bg = '#344353' },
      DiffviewDiffDelete = { bg = '#433234' },
      DiffviewDiffText = { bg = '#385070' },
      DiffviewDiffAddAsDelete = { bg = '#433234' },
      DiffviewDiffDeleteDim = { bg = '#322628' },
      DiffviewDiffAddDim = { bg = '#263225' },
    },
  })
  require('helix').load()
end

return M
