return {
  'akinsho/bufferline.nvim',
  event = 'VeryLazy',
  version = '*',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  opts = {
    options = {
      -- Close command
      close_command = 'bdelete! %d',
      right_mouse_command = 'bdelete! %d',

      -- Enable LSP diagnostics
      diagnostics = 'nvim_lsp',

      -- Diagnostics indicator with icons
      diagnostics_indicator = function(count, level, diagnostics_dict, context)
        local icon = level:match('error') and ' ' or ' '
        return ' ' .. icon .. count
      end,

      -- Only show when multiple buffers
      always_show_bufferline = true,

      -- Separator style
      separator_style = 'thin',

      -- Offset for file explorer
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'File Explorer',
          text_align = 'left',
          highlight = 'Directory',
          separator = true,
        },
      },

      -- Underline indicator for selected buffer
      indicator = {
        style = 'underline',
      },

      -- Show buffer close icons
      show_buffer_close_icons = true,
      show_close_icon = true,
    },
    highlights = {
      -- Selected buffer with underline
      buffer_selected = {
        bold = true,
        underline = true,
      },
      -- Underline diagnostics in selected buffer
      diagnostic_selected = {
        underline = true,
      },
      error_selected = {
        underline = true,
      },
      error_diagnostic_selected = {
        underline = true,
      },
      warning_selected = {
        underline = true,
      },
      warning_diagnostic_selected = {
        underline = true,
      },
      info_selected = {
        underline = true,
      },
      info_diagnostic_selected = {
        underline = true,
      },
      hint_selected = {
        underline = true,
      },
      hint_diagnostic_selected = {
        underline = true,
      },
    },
  },
  config = function(_, opts)
    require('bufferline').setup(opts)

    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
}
