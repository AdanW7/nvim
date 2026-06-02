local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/nvim-lualine/lualine.nvim',
  }, { load = true, confirm = false })

  require('lualine').setup({
    options = {
      theme = 'auto',
      component_separators = { left = '', right = '' },
      section_separators = { left = '', right = '' },
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = {
        'filename',
        {
          function()
            local blame = vim.b.gitsigns_blame_line
            if blame then
              return blame
            end
            return ''
          end,
          icon = '',
          color = { fg = '#7a7c7e' },
        },
      },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
  })
end

return M
