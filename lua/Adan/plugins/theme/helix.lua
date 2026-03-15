---@type LazySpec
return {
  'AdanW7/helix.nvim',
  lazy = false,
  priority = 1000,
  config = function()
    require('helix').setup({
      -- Transparent background (for transparent terminals)
      transparent = false,

      -- Enable terminal colors
      term_colors = true,

      -- Show end-of-buffer tildes
      ending_tildes = false,

      -- Code style options
      code_style = {
        comments = 'italic', -- 'italic', 'bold', 'underline', 'none'
        keywords = 'none',
        functions = 'none',
        strings = 'none',
        variables = 'none',
        constants = 'none',
      },

      -- Diagnostics appearance
      diagnostics = {
        darker = false, -- Use darker diagnostic colors
        undercurl = true, -- Use undercurl for diagnostics
        background = false, -- Use background color for virtual text
      },

      -- Override specific colors (optional)
      colors = {
        -- Example: red = "#ff0000",
      },

      -- Override highlight groups (optional)
      highlights = {
        SnacksIndent = { fg = '#5f79a6' },
        SnacksIndentScope = { fg = '#7394cf', fmt = 'bold' },
        -- Soften diff backgrounds for readability
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
  end,
}
