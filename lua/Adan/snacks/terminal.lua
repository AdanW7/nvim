return {
  'folke/snacks.nvim',
  opts = function()
    local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

    return {
      terminal = {
        win = {
          style = 'terminal',
        },
        -- Set shell to PowerShell on Windows
        shell = is_windows and 'pwsh.exe' or vim.o.shell,
      },
    }
  end,
  keys = {
    {
      '<leader>ts',
      function()
        Snacks.terminal(nil, { win = { position = 'bottom' } })
      end,
      desc = 'Toggle Terminal (split)',
    },
    {
      '<c-/>',
      function()
        Snacks.terminal()
      end,
      desc = 'Toggle Terminal',
      mode = { 'n', 't' },
    },
  },
}
