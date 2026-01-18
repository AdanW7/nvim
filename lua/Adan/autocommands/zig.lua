local zig_group = vim.api.nvim_create_augroup('ZigAutocommands', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = zig_group,
  pattern = 'zig',
  callback = function(args)
    local bufnr = args.buf

    -- Set errorformat for Zig compiler output
    vim.opt_local.errorformat = '%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l:%c: %tote: %m'
    vim.opt_local.makeprg = 'zig build'

    -- Helper to run command with quickfix
    local function zig_make(cmd)
      vim.opt_local.makeprg = cmd
      vim.cmd('make')
      vim.defer_fn(function()
        if vim.fn.getqflist({ size = 0 }).size > 0 then
          vim.cmd('copen')
        else
          vim.cmd('cclose')
        end
      end, 50)
    end

    local ok, wk = pcall(require, 'which-key')
    if ok then
      wk.add({ { '<leader>lb', group = 'Zig Build', buffer = bufnr } })
    end

    vim.keymap.set('n', '<leader>lf', ':!zig fmt %<CR>', { buffer = bufnr, desc = 'Format file' })

    vim.keymap.set('n', '<leader>lbp', function()
      zig_make('zig build')
    end, { buffer = bufnr, desc = 'Build project' })

    vim.keymap.set('n', '<leader>lbr', function()
      zig_make('zig build run')
    end, { buffer = bufnr, desc = 'Build and run' })

    vim.keymap.set('n', '<leader>lbt', function()
      zig_make('zig build test')
    end, { buffer = bufnr, desc = 'Build and test' })

    vim.keymap.set('n', '<leader>lbe', function()
      local file = vim.fn.expand('%')
      local exe = vim.fn.expand('%:t:r')
      zig_make('zig build-exe ' .. file .. ' -femit-bin=' .. exe)
    end, { buffer = bufnr, desc = 'Build exe from file' })
  end,
  desc = 'Set Zig keybindings',
})
