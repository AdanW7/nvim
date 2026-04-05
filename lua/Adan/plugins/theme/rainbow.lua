local M = {}

function M.setup()
  vim.pack.add(
    { 'https://github.com/HiPhish/rainbow-delimiters.nvim' },
    { load = true, confirm = false }
  )

  local opts = {
    strategy = {
      [''] = 'rainbow-delimiters.strategy.global',
      vim = 'rainbow-delimiters.strategy.local',
    },
    query = {
      [''] = 'rainbow-delimiters',
      lua = 'rainbow-blocks',
    },
    priority = {
      [''] = 110,
      lua = 210,
    },
    highlight = {
      'RainbowDelimiterRed',
      'RainbowDelimiterYellow',
      'RainbowDelimiterBlue',
      'RainbowDelimiterOrange',
      'RainbowDelimiterGreen',
      'RainbowDelimiterViolet',
      'RainbowDelimiterCyan',
    },
  }

  local function apply_bright_helix_rainbow_hl()
    local palette = {
      RainbowDelimiterRed = '#ef7e7e',
      RainbowDelimiterYellow = '#f4d67a',
      RainbowDelimiterBlue = '#71baf2',
      RainbowDelimiterOrange = '#ffb366',
      RainbowDelimiterGreen = '#96d988',
      RainbowDelimiterViolet = '#ce89df',
      RainbowDelimiterCyan = '#67cbe7',
    }
    for group, color in pairs(palette) do
      vim.api.nvim_set_hl(0, group, { fg = color, bold = true, nocombine = true })
    end
  end

  vim.g.rainbow_delimiters = opts
  apply_bright_helix_rainbow_hl()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('AdanRainbowDelimitersColors', { clear = true }),
    callback = apply_bright_helix_rainbow_hl,
  })
end

return M
