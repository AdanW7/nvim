local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/danymat/neogen' }, { load = true, confirm = false })

  require('neogen').setup({
    enabled = true,
    snippet_engine = 'luasnip',
    placeholders_text = {
      ['description'] = '',
      ['tparam'] = '',
      ['parameter'] = '',
      ['return'] = '',
      ['class'] = '',
      ['throw'] = '',
      ['varargs'] = '',
      ['type'] = '',
      ['attribute'] = '',
      ['args'] = '',
      ['kwargs'] = '',
    },
    languages = {
      c = {
        template = {
          annotation_convention = 'doxygen_javadoc',
        },
      },
      cpp = {
        template = {
          annotation_convention = 'doxygen_javadoc',
        },
      },
    },
  })
  vim.keymap.set('n', '<leader>lcf', function()
    require('neogen').generate({ type = 'func' })
  end, { desc = 'Neogen: function annotation' })

  vim.keymap.set('n', '<leader>lcc', function()
    require('neogen').generate({ type = 'class' })
  end, { desc = 'Neogen: class annotation' })

  vim.keymap.set('n', '<leader>lct', function()
    require('neogen').generate({ type = 'type' })
  end, { desc = 'Neogen: type annotation' })
end

return M
