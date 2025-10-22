local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/lewis6991/gitsigns.nvim' }, { load = true, confirm = false })

  require('gitsigns').setup({
    signs = {
      add = { text = '+' },
      change = { text = '│' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    signs_staged = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    signs_staged_enable = true,
    watch_gitdir = {
      enable = true,
      follow_files = true,
    },
    update_debounce = 100,
    current_line_blame = true,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol',
      delay = 500,
      ignore_whitespace = false,
      virt_text_priority = 100,
      use_focus = true,
    },
    current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
    on_attach = function(bufnr)
      local gs = require('gitsigns')

      vim.keymap.set('n', '<leader>gbb', gs.toggle_current_line_blame, {
        buffer = bufnr,
        desc = 'Toggle Git Blame (inline)',
      })

      vim.keymap.set('n', ']h', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          gs.nav_hunk('next')
        end
      end, { buffer = bufnr, desc = 'Next hunk' })

      vim.keymap.set('n', '[h', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          gs.nav_hunk('prev')
        end
      end, { buffer = bufnr, desc = 'Prev hunk' })

      vim.keymap.set('n', '<leader>hs', gs.stage_hunk, { buffer = bufnr, desc = 'Stage hunk' })
      vim.keymap.set('n', '<leader>hr', gs.reset_hunk, { buffer = bufnr, desc = 'Reset hunk' })
      vim.keymap.set('n', '<leader>hS', gs.stage_buffer, { buffer = bufnr, desc = 'Stage buffer' })
      vim.keymap.set('n', '<leader>hR', gs.reset_buffer, { buffer = bufnr, desc = 'Reset buffer' })
      vim.keymap.set('n', '<leader>hp', gs.preview_hunk, { buffer = bufnr, desc = 'Preview hunk' })
      vim.keymap.set('n', '<leader>hb', function()
        gs.blame_line({ full = true })
      end, { buffer = bufnr, desc = 'Blame line (popup)' })
      vim.keymap.set('n', '<leader>hd', gs.diffthis, { buffer = bufnr, desc = 'Diff this' })
      vim.keymap.set('n', '<leader>gR', gs.refresh, { buffer = bufnr, desc = 'Refresh git signs' })

      vim.keymap.set('v', '<leader>hs', function()
        gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { buffer = bufnr, desc = 'Stage hunk (visual)' })

      vim.keymap.set('v', '<leader>hr', function()
        gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { buffer = bufnr, desc = 'Reset hunk (visual)' })

      vim.keymap.set({ 'o', 'x' }, 'ih', gs.select_hunk, { buffer = bufnr, desc = 'Select hunk' })
    end,
  })
end

return M
