local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/MeanderingProgrammer/render-markdown.nvim',
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-mini/mini.icons',
  }, { load = true, confirm = false })

  require('render-markdown').setup({
    completions = {
      lsp = {
        enabled = true,
      },
    },
    heading = {
      border = true,
    },
    overrides = {
      buftype = {
        nofile = {},
      },
    },
  })
end

return M
