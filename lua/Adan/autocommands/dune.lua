local dune_group = vim.api.nvim_create_augroup('DuneAutocommands', { clear = true })

-- Store last executable name across buffer instances
local last_executable = nil

vim.api.nvim_create_autocmd('FileType', {
  group = dune_group,
  pattern = 'ocaml',
  callback = function(args)
    local bufnr = args.buf
    local opts = { buffer = bufnr, silent = true }

    -- Set errorformat for Dune/OCaml compiler output
    vim.opt_local.errorformat = '%EFile "%f"\\, line %l\\, characters %c-%*\\d:,%ZError: %m,%C%m'
    vim.opt_local.makeprg = 'dune build'

    -- Helper to find dune project root
    local function find_dune_project()
      local current = vim.fn.expand('%:p:h')
      while current ~= '/' do
        if vim.fn.filereadable(current .. '/dune-project') == 1 then
          return current
        end
        current = vim.fn.fnamemodify(current, ':h')
      end
      return vim.fn.getcwd()
    end

    -- Helper to find executable name from dune file
    local function find_executable()
      local project_root = find_dune_project()

      -- Try bin/dune first, then root dune
      for _, path in ipairs({ '/bin/dune', '/dune' }) do
        local dune_file = project_root .. path
        if vim.fn.filereadable(dune_file) == 1 then
          local lines = vim.fn.readfile(dune_file)
          for _, line in ipairs(lines) do
            local exe_name = line:match('%s*%(name%s+([^%)]+)%)')
            if exe_name then
              return exe_name
            end
          end
        end
      end

      return nil
    end

    -- Helper to run build commands with quickfix
    local function dune_make(cmd, desc)
      local project_root = find_dune_project()
      vim.opt_local.makeprg = 'cd ' .. vim.fn.shellescape(project_root) .. ' && ' .. cmd
      vim.cmd('make')
      vim.defer_fn(function()
        if vim.fn.getqflist({ size = 0 }).size > 0 then
          vim.cmd('copen')
          vim.notify(desc .. ' completed with errors', vim.log.levels.WARN)
        else
          vim.cmd('cclose')
          vim.notify(desc .. ' successful', vim.log.levels.INFO)
        end
      end, 100)
    end

    -- Helper to run exec commands in terminal
    local function dune_exec_terminal(cmd, desc)
      local project_root = find_dune_project()
      vim.cmd(
        'botright 15split | terminal cd ' .. vim.fn.shellescape(project_root) .. ' && ' .. cmd
      )
      vim.cmd('startinsert')
    end

    -- Helper to run commands asynchronously with output capture
    local function dune_cmd_async(cmd, desc)
      local project_root = find_dune_project()
      local output = {}

      vim.fn.jobstart('cd ' .. vim.fn.shellescape(project_root) .. ' && ' .. cmd, {
        on_stdout = function(_, data)
          if data then
            vim.list_extend(output, data)
          end
        end,
        on_stderr = function(_, data)
          if data then
            vim.list_extend(output, data)
          end
        end,
        on_exit = function(_, code)
          if code == 0 then
            vim.notify(desc .. ' successful', vim.log.levels.INFO)
          else
            vim.notify(desc .. ' failed', vim.log.levels.ERROR)
            -- Show output in a scratch buffer
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
            vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
            vim.api.nvim_buf_set_option(buf, 'filetype', 'duneoutput')
            vim.cmd('botright 15split')
            vim.api.nvim_win_set_buf(0, buf)
          end
        end,
        stdout_buffered = true,
        stderr_buffered = true,
      })
    end

    -- Register which-key group if available
    local ok, wk = pcall(require, 'which-key')
    if ok then
      wk.add({
        { '<leader>ld', group = 'Dune', buffer = bufnr },
        { '<leader>lde', group = 'Dune Exec', buffer = bufnr },
      })
    end

    -- Build project (uses quickfix)
    vim.keymap.set('n', '<leader>ldb', function()
      dune_make('dune build', 'Dune build')
    end, vim.tbl_extend('force', opts, { desc = 'Build project' }))

    -- Build in watch mode (continuous) - runs in terminal
    vim.keymap.set('n', '<leader>ldw', function()
      dune_exec_terminal('dune build --watch', 'Dune watch')
    end, vim.tbl_extend('force', opts, { desc = 'Build (watch mode)' }))

    -- Run tests (uses quickfix)
    vim.keymap.set('n', '<leader>ldt', function()
      dune_make('dune test', 'Dune test')
    end, vim.tbl_extend('force', opts, { desc = 'Run tests' }))

    -- Run specific executable (in terminal for interactive output)
    vim.keymap.set('n', '<leader>lder', function()
      local exe_name = vim.fn.input('Executable name: ')
      if exe_name ~= '' then
        last_executable = exe_name
        dune_exec_terminal('dune exec ' .. exe_name, 'Dune exec ' .. exe_name)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Run executable (prompt)' }))

    -- Run executable (smart default from last used or auto-detected)
    vim.keymap.set('n', '<leader>ldee', function()
      local default = last_executable or find_executable() or ''
      local exe = vim.fn.input('Executable name: ', default)
      if exe and exe ~= '' then
        last_executable = exe
        dune_exec_terminal('dune exec ' .. exe, 'Dune exec ' .. exe)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Run executable (smart default)' }))

    -- Run last/default executable without prompting
    vim.keymap.set('n', '<leader>ldel', function()
      local exe = last_executable or find_executable()
      if exe then
        last_executable = exe
        dune_exec_terminal('dune exec ' .. exe, 'Dune exec ' .. exe)
      else
        vim.notify('No executable found. Use <leader>ldee first.', vim.log.levels.WARN)
      end
    end, vim.tbl_extend('force', opts, { desc = 'Run last/default executable' }))

    -- Clean build artifacts
    vim.keymap.set('n', '<leader>ldc', function()
      dune_cmd_async('dune clean', 'Dune clean')
    end, vim.tbl_extend('force', opts, { desc = 'Clean build artifacts' }))

    -- Format file with ocamlformat
    vim.keymap.set('n', '<leader>ldf', function()
      vim.fn.jobstart('ocamlformat --inplace ' .. vim.fn.expand('%'), {
        on_exit = function(_, code)
          if code == 0 then
            vim.cmd('edit') -- Reload file
            vim.notify('File formatted', vim.log.levels.INFO)
          else
            vim.notify('Format failed', vim.log.levels.ERROR)
          end
        end,
      })
    end, vim.tbl_extend('force', opts, { desc = 'Format file' }))

    -- Build with profile (uses quickfix)
    vim.keymap.set('n', '<leader>ldp', function()
      local profile = vim.fn.input('Profile (release/dev): ', 'release')
      if profile ~= '' then
        dune_make('dune build --profile=' .. profile, 'Dune build (' .. profile .. ')')
      end
    end, vim.tbl_extend('force', opts, { desc = 'Build with profile' }))

    -- Install dependencies
    vim.keymap.set('n', '<leader>ldi', function()
      dune_cmd_async('dune install', 'Dune install')
    end, vim.tbl_extend('force', opts, { desc = 'Install dependencies' }))

    -- Stop watch mode (if running in terminal, just close the terminal)
    vim.keymap.set('n', '<leader>ldq', function()
      vim.fn.jobstart('pkill -f "dune build --watch"', {
        on_exit = function()
          vim.notify('Stopped Dune watch mode', vim.log.levels.INFO)
        end,
      })
    end, vim.tbl_extend('force', opts, { desc = 'Stop watch mode' }))

    -- Run REPL (utop) in terminal
    vim.keymap.set('n', '<leader>ldu', function()
      dune_exec_terminal('dune utop', 'Dune utop')
    end, vim.tbl_extend('force', opts, { desc = 'Open REPL (utop)' }))
  end,
  desc = 'Set Dune keybindings',
})

-- OCaml-specific settings
vim.api.nvim_create_autocmd('FileType', {
  group = dune_group,
  pattern = 'ocaml',
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
    vim.opt_local.commentstring = '(* %s *)'
  end,
})
