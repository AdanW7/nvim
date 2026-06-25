local M = {}
function M.setup()
  vim.pack.add({
    'https://github.com/chrisgrieser/nvim-origami',
  }, { load = false, confirm = false })

  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99

  -- Keymaps registered immediately with lazy requires
  local fold_util = require('Adan.utils.code_folds')
  vim.keymap.set('n', 'H', 'za', { noremap = true, silent = true, desc = 'Toggle fold' })
  vim.keymap.set('n', 'zk', fold_util.goto_previous_fold, {
    noremap = true,
    silent = true,
    desc = 'Go to previous fold',
  })
  vim.keymap.set('n', 'zj', 'zj', { noremap = true, silent = true, desc = 'Go to next fold' })
  vim.keymap.set('n', '<Left>', function()
    require('origami').h()
  end)
  vim.keymap.set('n', '<Right>', function()
    require('origami').l()
  end)
  vim.keymap.set('n', '<End>', function()
    require('origami').dollar()
  end)

  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = function()
      require('origami').setup({
        useLspFoldsWithTreesitterFallback = {
          enabled = true,
          foldmethodIfNeitherIsAvailable = 'indent',
        },
        foldtext = {
          lineCount = { template = ' %d Lines' },
          diagnosticsCount = true,
          gitsignsCount = true,
        },
        foldKeymaps = {
          setup = false,
          hOnlyOpensOnFirstColumn = false,
        },
        autoFold = {
          enabled = true,
          kinds = { 'comment', 'imports' },
        },
      })
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'LspAttach' }, {
    callback = function(opts)
      fold_util.update_ranges(opts.buf)
    end,
  })

  local last_row = nil
  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function(opts)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      if row ~= last_row then
        last_row = row
        fold_util.update_current_fold(row, opts.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
    callback = function(opts)
      fold_util.clear(opts.buf)
    end,
  })

  vim.opt.statuscolumn = '%!v:lua.StatusCol()'
  function _G.StatusCol()
    return fold_util.statuscol()
  end
end
return M
