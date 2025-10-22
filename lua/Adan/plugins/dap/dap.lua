local M = {}

function M.setup()
  local specs = {
    'https://github.com/mfussenegger/nvim-dap',
    'https://github.com/rcarriga/nvim-dap-ui',
    'https://github.com/theHamsta/nvim-dap-virtual-text',
    'https://github.com/nvim-neotest/nvim-nio',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/jay-babu/mason-nvim-dap.nvim',
    'https://github.com/leoluz/nvim-dap-go',
  }

  if vim.fn.has('unix') == 1 then
    table.insert(specs, 'https://github.com/mfussenegger/nvim-dap-python')
  end

  vim.pack.add(specs, { load = true, confirm = false })

  require('mason-nvim-dap').setup({
    ensure_installed = { 'codelldb' },
    automatic_setup = false,
  })

  require('Adan.dap.ui')
  require('Adan.dap.adapters.lldb')
  require('Adan.dap.adapters.go')
  require('Adan.dap.adapters.python')

  require('Adan.dap.configurations.zig')
  require('Adan.dap.configurations.c')
  require('Adan.dap.configurations.cpp')
  require('Adan.dap.configurations.rust')
end

return M
