local dap = require('dap')
local dapui = require('dapui')
local keymap = vim.keymap.set

-- Breakpoint management
keymap('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Toggle breakpoint' })
keymap('n', '<leader>dB', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = 'Conditional breakpoint' })

-- Debug session control
keymap('n', '<leader>dc', dap.continue, { desc = 'Continue/Start debugging' })
keymap('n', '<leader>di', dap.step_into, { desc = 'Step into' })
keymap('n', '<leader>do', dap.step_over, { desc = 'Step over' })
keymap('n', '<leader>dO', dap.step_out, { desc = 'Step out' })
keymap('n', '<leader>dt', dap.terminate, { desc = 'Terminate debug session' })
keymap('n', '<leader>dr', dap.restart, { desc = 'Restart debugger' })

-- UI controls
keymap('n', '<leader>du', dapui.toggle, { desc = 'Toggle DAP UI' })
keymap('n', '<leader>de', function()
  dapui.eval(nil, { enter = true })
end, { desc = 'Evaluate expression' })

-- Run to cursor
keymap('n', '<leader>dC', dap.run_to_cursor, { desc = 'Run to cursor' })

-- F-key bindings
keymap('n', '<F5>', dap.continue, { desc = 'Continue' })
keymap('n', '<F10>', dap.step_over, { desc = 'Step over' })
keymap('n', '<F11>', dap.step_into, { desc = 'Step into' })
keymap('n', '<F12>', dap.step_out, { desc = 'Step out' })

-- Register which-key groups
local ok, wk = pcall(require, 'which-key')
if ok then
  wk.add({
    { '<leader>d', group = 'Debug' },
  })
end
