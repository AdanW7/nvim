local M = {}

local function toggle_terminal()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == 't' then
    local esc = vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', false)
    vim.schedule(function()
      Snacks.terminal()
    end)
    return
  end
  Snacks.terminal()
end

function M.extend_opts(opts)
  local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

  opts.terminal = vim.tbl_deep_extend('force', opts.terminal or {}, {
    win = {
      style = 'terminal',
    },
    shell = is_windows and 'pwsh.exe' or vim.o.shell,
  })
end

function M.keys()
  return {
    {
      lhs = '<leader>ts',
      rhs = function()
        Snacks.terminal(nil, { win = { position = 'bottom' } })
      end,
      desc = 'Toggle Terminal (split)',
    },
    {
      lhs = '<c-/>',
      rhs = function()
        toggle_terminal()
      end,
      desc = 'Toggle Terminal',
      mode = { 'n', 't' },
    },
    {
      lhs = '<c-_>',
      rhs = function()
        toggle_terminal()
      end,
      desc = 'Toggle Terminal',
      mode = { 'n', 't' },
    },
  }
end

return M
