local M = {
  _loaded = false,
}

local function with_dap(action)
  local ok, err = M.load()
  if not ok then
    vim.notify(('DAP failed to load: %s'):format(err), vim.log.levels.ERROR)
    return
  end

  local ok_action, action_err = pcall(action)
  if not ok_action then
    vim.notify(('DAP action failed: %s'):format(action_err), vim.log.levels.ERROR)
  end
end

function M.load()
  if M._loaded then
    return true
  end

  local ok, mod = pcall(require, 'Adan.plugins.dap.dap')
  if not ok then
    return false, mod
  end

  local ok_setup, err = pcall(mod.setup)
  if not ok_setup then
    return false, err
  end

  M._loaded = true
  return true
end

function M.setup()
  vim.api.nvim_create_user_command('DapLoad', function()
    local ok, err = M.load()
    if not ok then
      vim.notify(('DAP failed to load: %s'):format(err), vim.log.levels.ERROR)
      return
    end
    vim.notify('DAP loaded', vim.log.levels.INFO)
  end, { desc = 'Load DAP stack' })

  vim.keymap.set('n', '<leader>db', function()
    with_dap(function()
      require('dap').toggle_breakpoint()
    end)
  end, { desc = 'Toggle breakpoint' })

  vim.keymap.set('n', '<leader>dB', function()
    with_dap(function()
      require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
    end)
  end, { desc = 'Conditional breakpoint' })

  vim.keymap.set('n', '<leader>dc', function()
    with_dap(function()
      require('dap').continue()
    end)
  end, { desc = 'Continue/Start debugging' })

  vim.keymap.set('n', '<leader>di', function()
    with_dap(function()
      require('dap').step_into()
    end)
  end, { desc = 'Step into' })

  vim.keymap.set('n', '<leader>do', function()
    with_dap(function()
      require('dap').step_over()
    end)
  end, { desc = 'Step over' })

  vim.keymap.set('n', '<leader>dO', function()
    with_dap(function()
      require('dap').step_out()
    end)
  end, { desc = 'Step out' })

  vim.keymap.set('n', '<leader>dt', function()
    with_dap(function()
      require('dap').terminate()
    end)
  end, { desc = 'Terminate debug session' })

  vim.keymap.set('n', '<leader>dr', function()
    with_dap(function()
      require('dap').restart()
    end)
  end, { desc = 'Restart debugger' })

  vim.keymap.set('n', '<leader>du', function()
    with_dap(function()
      require('dapui').toggle()
    end)
  end, { desc = 'Toggle DAP UI' })

  vim.keymap.set('n', '<leader>de', function()
    with_dap(function()
      require('dapui').eval(nil, { enter = true })
    end)
  end, { desc = 'Evaluate expression' })

  vim.keymap.set('n', '<leader>dC', function()
    with_dap(function()
      require('dap').run_to_cursor()
    end)
  end, { desc = 'Run to cursor' })

  vim.keymap.set('n', '<F5>', function()
    with_dap(function()
      require('dap').continue()
    end)
  end, { desc = 'Continue' })

  vim.keymap.set('n', '<F10>', function()
    with_dap(function()
      require('dap').step_over()
    end)
  end, { desc = 'Step over' })

  vim.keymap.set('n', '<F11>', function()
    with_dap(function()
      require('dap').step_into()
    end)
  end, { desc = 'Step into' })

  vim.keymap.set('n', '<F12>', function()
    with_dap(function()
      require('dap').step_out()
    end)
  end, { desc = 'Step out' })

  local ok, wk = pcall(require, 'which-key')
  if ok then
    wk.add({
      { '<leader>d', group = 'Debugger' },
    })
  end
end

return M
