local group = vim.api.nvim_create_augroup('AdanEditingAutocmds', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'qf',
  desc = 'Attach keymaps for quickfix list',
  callback = function()
    local qf_history = {}

    local function save_history()
      table.insert(qf_history, vim.fn.getqflist())
    end

    -- dd: remove item under cursor
    vim.keymap.set(
      'n',
      'dd',
      function()
        local qf_list = vim.fn.getqflist()
        local current_line_number = vim.fn.line('.')
        if qf_list[current_line_number] then
          save_history()
          table.remove(qf_list, current_line_number)
          vim.fn.setqflist(qf_list, 'r')
          vim.fn.cursor(math.min(current_line_number, #qf_list), 1)
        end
      end,
      { buffer = true, noremap = true, silent = true, desc = 'Remove quickfix item under cursor' }
    )

    -- d: remove visual selection
    vim.keymap.set({ 'v' }, 'd', function()
      local qf_list = vim.fn.getqflist()
      local start_line = vim.fn.line('v')
      local end_line = vim.fn.line('.')
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      save_history()
      for _ = start_line, end_line do
        table.remove(qf_list, start_line)
      end
      vim.fn.setqflist(qf_list, 'r')
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.fn.cursor(math.min(start_line, #qf_list), 1)
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = 'Remove selected quickfix items',
    })

    -- o: open item but stay in quickfix window
    vim.keymap.set('n', 'o', function()
      local qf_win = vim.api.nvim_get_current_win()
      vim.cmd('cc ' .. vim.fn.line('.'))
      vim.api.nvim_set_current_win(qf_win)
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = 'Open quickfix item, stay in quickfix',
    })

    -- O: open item in vertical split of the window above, or a new vsplit
    vim.keymap.set('n', 'O', function()
      local item = vim.fn.getqflist()[vim.fn.line('.')]
      if not item then
        return
      end
      local fname = vim.api.nvim_buf_get_name(item.bufnr)
      local qf_win = vim.api.nvim_get_current_win()
      local qf_pos = vim.api.nvim_win_get_position(qf_win)

      local target_win = nil
      local closest_y = -1

      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= qf_win then
          local pos = vim.api.nvim_win_get_position(win)
          local win_width = vim.api.nvim_win_get_width(win)
          local qf_width = vim.api.nvim_win_get_width(qf_win)
          local win_end_col = pos[2] + win_width
          local qf_end_col = qf_pos[2] + qf_width
          local overlaps_horizontally = pos[2] < qf_end_col and win_end_col > qf_pos[2]

          if pos[1] < qf_pos[1] and overlaps_horizontally and pos[1] > closest_y then
            closest_y = pos[1]
            target_win = win
          end
        end
      end

      if target_win then
        vim.api.nvim_set_current_win(target_win)
        vim.cmd('vsplit ' .. vim.fn.fnameescape(fname))
      else
        vim.cmd('vsplit ' .. vim.fn.fnameescape(fname))
      end
      vim.api.nvim_win_set_cursor(0, { item.lnum, math.max(0, item.col - 1) })
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = 'Open quickfix item in vertical split of window above',
    })

    -- <C-q>: send visual selection to a new quickfix list
    vim.keymap.set({ 'v' }, '<C-q>', function()
      local qf_list = vim.fn.getqflist()
      local start_line = vim.fn.line('v')
      local end_line = vim.fn.line('.')
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      local selected = vim.list_slice(qf_list, start_line, end_line)
      vim.fn.setqflist(selected, ' ')
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', false)
      vim.cmd('copen')
    end, {
      buffer = true,
      noremap = true,
      silent = true,
      desc = 'Send selected items to new quickfix list',
    })
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  pattern = '*',
  callback = function()
    local view = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
  desc = 'Strip trailing whitespace before saving',
})

vim.api.nvim_create_autocmd('BufWritePre', {
  callback = function(args)
    if vim.bo[args.buf].buftype ~= '' then
      return
    end

    if args.match:match('^%w+://') then
      return
    end

    local file = vim.uv.fs_realpath(args.match) or args.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
  group = group,
})

vim.api.nvim_create_autocmd('InsertEnter', {
  group = group,
  callback = function(args)
    vim.b[args.buf].diagnostics_enabled_before_insert = vim.diagnostic.is_enabled({ bufnr = args.buf })
    vim.diagnostic.enable(false, { bufnr = args.buf })
  end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
  group = group,
  callback = function(args)
    if vim.b[args.buf].diagnostics_enabled_before_insert then
      vim.diagnostic.enable(true, { bufnr = args.buf })
    end
    vim.b[args.buf].diagnostics_enabled_before_insert = nil
  end,
})
