local function toggle_terminal()
  local mode = vim.api.nvim_get_mode().mode
  if mode:sub(1, 1) == 't' then
    -- Leave terminal-job mode first, then toggle the terminal window.
    local esc = vim.api.nvim_replace_termcodes('<C-\\><C-n>', true, false, true)
    vim.api.nvim_feedkeys(esc, 'n', false)
    vim.schedule(function()
      Snacks.terminal()
    end)
    return
  end
  Snacks.terminal()
end

---@type Adan.LazySpec
return {
  'folke/snacks.nvim',
  opts = function(_, opts)
    local is_windows = vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1

    opts = opts or {}
    opts.terminal = vim.tbl_deep_extend('force', opts.terminal or {}, {
      win = {
        style = 'terminal',
      },
      -- Set shell to PowerShell on Windows
      shell = is_windows and 'pwsh.exe' or vim.o.shell,
    })
    return opts
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
        toggle_terminal()
      end,
      desc = 'Toggle Terminal',
      mode = { 'n', 't' },
    },
    {
      '<c-_>',
      function()
        toggle_terminal()
      end,
      desc = 'Toggle Terminal',
      mode = { 'n', 't' },
    },
  },
}
