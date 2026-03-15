---@type LazySpec
return {
  'lewis6991/hover.nvim',
  event = 'LspAttach',
  config = function()
    require('hover').config({
      providers = {
        'hover.providers.diagnostic',
        'hover.providers.lsp',
        'hover.providers.dap',
        'hover.providers.man',
        'hover.providers.dictionary',
      },
      preview_opts = {
        border = 'single',
      },
      preview_window = false,
      title = true,
    })
  end,
  keys = {
    {
      'K',
      function()
        require('hover').open()
      end,
      desc = 'Hover',
    },
    {
      'gK',
      function()
        require('hover').enter()
      end,
      desc = 'Hover (enter)',
    },
  },
}
