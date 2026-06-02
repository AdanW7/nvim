local M = {}

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/akinsho/bufferline.nvim', version = 'main' },
  }, { load = true, confirm = false })

  local function scope_close(bufnr)
    local ok_scope, scope_core = pcall(require, 'scope.core')
    if ok_scope and type(scope_core.close_buffer) == 'function' then
      scope_core.close_buffer({ buf = bufnr, force = true, ask = false })
      return
    end
    pcall(vim.cmd, ('bdelete! %d'):format(bufnr))
  end

  local opts = {
    options = {
      close_command = scope_close,
      right_mouse_command = scope_close,
      diagnostics = 'nvim_lsp',
      diagnostics_indicator = function(count, level)
        local icon = level:match('error') and ' ' or ' '
        return ' ' .. icon .. count
      end,
      always_show_bufferline = true,
      separator_style = 'thin',
      offsets = {
        {
          filetype = 'neo-tree',
          text = 'File Explorer',
          text_align = 'left',
          highlight = 'Directory',
          separator = true,
        },
      },
      indicator = {
        style = 'underline',
      },
      show_buffer_close_icons = true,
      show_close_icon = true,
    },
    highlights = {
      buffer_selected = {
        bold = true,
        underline = true,
      },
      diagnostic_selected = { underline = true },
      error_selected = { underline = true },
      error_diagnostic_selected = { underline = true },
      warning_selected = { underline = true },
      warning_diagnostic_selected = { underline = true },
      info_selected = { underline = true },
      info_diagnostic_selected = { underline = true },
      hint_selected = { underline = true },
      hint_diagnostic_selected = { underline = true },
    },
  }

  require('bufferline').setup(opts)

  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete' }, {
    callback = function()
      vim.schedule(function()
        pcall(vim.cmd, 'silent! BufferLineCycleNext')
        pcall(vim.cmd, 'silent! BufferLineCyclePrev')
      end)
    end,
  })
end

return M
