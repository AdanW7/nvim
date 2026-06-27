local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/folke/which-key.nvim' }, { load = true, confirm = false })

  require('which-key').setup({
    preset = 'helix',
    delay = 0,
    spec = {
      { '<leader>b', group = 'Buffers' },
      { '<leader>d', group = 'Debugger' },
      { '<leader>w', group = 'Windows' },
      { '<leader>t', group = 'Tabs' },
      { '<leader>y', group = 'Yank' },
      { 'y', desc = 'Yank' },
      { 'Y', desc = 'Yank line' },
      { 'p', desc = 'Paste after' },
      { 'P', desc = 'Paste before' },
      { 't', group = 'Tab Navigation' },
      { 'm', group = 'Multi-cursor' },
      { 'g', group = 'Go to / LSP navigation' },
      { '<leader>tc', group = 'Close Tabs' },
      { '<leader>tm', group = 'Move Tabs' },
      { '<leader>l', group = 'LSP' },
      { '<leader>p', group = 'Paste' },
      { '<leader>P', group = 'Projects' },
      { '<leader>c', group = 'Mason and Change Directory' },
      { '<leader>q', group = 'Open / Close Quick fix list' },
      { '<leader>s', group = 'sessions' },
      { '<leader>r', group = 'Reload' },
      { '<leader>f', group = 'Telescope' },
      { '<leader>g', group = 'Git' },
      { '<leader>gb', group = 'Blame and Buffer options' },
      { '<leader>h', group = 'Git Staging' },
      { '<leader>wn', group = 'Scratch buffer in New Window' },
      -- Surround (normal + visual mode)
      { 's', group = 'Surround', mode = { 'n', 'x' } },
      { 'sa', desc = 'Add surrounding', mode = { 'n', 'x' } },
      { 'sd', desc = 'Delete surrounding', mode = 'n' },
      { 'sr', desc = 'Replace surrounding', mode = 'n' },
      { 'sf', desc = 'Find surrounding (right)', mode = 'n' },
      { 'sF', desc = 'Find surrounding (left)', mode = 'n' },
      { 'sh', desc = 'Highlight surrounding', mode = 'n' },
      -- mini.ai textobjects (visual + operator-pending only)
      { 'af', desc = 'Around function', mode = { 'x', 'o' } },
      { 'ac', desc = 'Around class', mode = { 'x', 'o' } },
      { 'ai', desc = 'Around conditional', mode = { 'x', 'o' } },
      { 'al', desc = 'Around loop', mode = { 'x', 'o' } },
      { 'aa', desc = 'Around parameter', mode = { 'x', 'o' } },
      { 'a/', desc = 'Around comment', mode = { 'x', 'o' } },
      { 'aB', desc = 'Around block', mode = { 'x', 'o' } },
      { 'aC', desc = 'Around call', mode = { 'x', 'o' } },
      { 'aT', desc = 'Around type', mode = { 'x', 'o' } },
      { 'if', desc = 'Inside function', mode = { 'x', 'o' } },
      { 'ic', desc = 'Inside class', mode = { 'x', 'o' } },
      { 'ii', desc = 'Inside conditional', mode = { 'x', 'o' } },
      { 'il', desc = 'Inside loop', mode = { 'x', 'o' } },
      { 'ia', desc = 'Inside parameter', mode = { 'x', 'o' } },
      { 'i/', desc = 'Inside comment', mode = { 'x', 'o' } },
      { 'iB', desc = 'Inside block', mode = { 'x', 'o' } },
      { 'iC', desc = 'Inside call', mode = { 'x', 'o' } },
      { 'iT', desc = 'Inside type', mode = { 'x', 'o' } },
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
