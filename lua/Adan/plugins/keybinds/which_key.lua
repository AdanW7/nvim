local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/folke/which-key.nvim' }, { load = true, confirm = false })

  require('which-key').setup({
    preset = 'helix',
    delay = 200,
    spec = {
      { '<leader>b', group = 'Buffers' },
      { '<leader>d', group = 'Debugger' },
      { '<leader>w', group = 'Windows' },
      { '<leader>t', group = 'Tabs/Terminal' },
      { 't', group = 'Tab Navigation' },
      { 'm', group = 'Multi-cursor' },
      { '<leader>tc', group = 'Close Tabs' },
      { '<leader>tm', group = 'Move Tabs' },
      { '<leader>l', group = 'LSP' },
      { '<leader>p', group = 'Paste' },
      { '<leader>P', group = 'Projects' },
      { '<leader>c', group = 'Navigate Quick fix list' },
      { '<leader>q', group = 'Open / Close Quick fix list' },
      { '<leader>s', group = 'sessions' },
      { '<leader>r', group = 'Reload' },
      { '<leader>f', group = 'Telescope' },
      { '<leader>g', group = 'Git' },
      { '<leader>gb', group = 'Blame and Buffer options' },
      { '<leader>h', group = 'Git Staging' },
      { '<leader>wn', group = 'Scratch buffer in New Window' },
    },
    plugins = {
      marks = true,
      registers = true,
      spelling = {
        enabled = true,
        suggestions = 20,
      },
      presets = {
        operators = true,
        motions = true,
        text_objects = true,
        windows = true,
        nav = true,
        z = true,
        g = true,
      },
    },
    win = {
      border = 'rounded',
      title = true,
      title_pos = 'center',
    },
    disable = {
      ft = { 'TelescopePrompt' },
      bt = { 'terminal' },
    },
    replace = {
      key = {
        { '<Space>', 'SPC' },
        { '<CR>', 'RET' },
        { '<Tab>', 'TAB' },
      },
    },
  })

  vim.keymap.set('n', '<leader>?', function()
    require('which-key').show({ global = false })
  end, { desc = 'Buffer Local Keymaps (which-key)' })
end

return M
