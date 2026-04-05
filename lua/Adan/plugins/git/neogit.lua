local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/NeogitOrg/neogit',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/sindrets/diffview.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
  }, { load = true, confirm = false })

  require('diffview').setup({
    diff_binaries = false,
    enhanced_diff_hl = true,
    use_icons = true,
    view = {
      default = {
        layout = 'diff2_horizontal',
      },
      merge_tool = {
        layout = 'diff3_horizontal',
      },
      file_history = {
        layout = 'diff2_horizontal',
      },
    },
  })

  require('neogit').setup({
    kind = 'tab',
    commit_editor = {
      kind = 'tab',
    },
    commit_popup = {
      kind = 'split',
    },
    signs = {
      hunk = { '', '' },
      item = { '', '' },
      section = { '', '' },
    },
    integrations = {
      telescope = true,
      diffview = true,
    },
    sections = {
      untracked = { folded = false },
      unstaged = { folded = false },
      staged = { folded = false },
      stashes = { folded = true },
      unpulled_upstream = { folded = true },
      unmerged_upstream = { folded = false },
      unpulled_pushRemote = { folded = true },
      unmerged_pushRemote = { folded = false },
      recent = { folded = true },
      rebase = { folded = true },
    },
    auto_show_console = true,
    remember_settings = true,
    use_per_project_settings = true,
    highlight = {
      italic = true,
      bold = true,
      underline = true,
    },
  })

  vim.keymap.set('n', '<leader>gn', '<cmd>Neogit<cr>', { desc = 'Show Neogit UI' })
  vim.keymap.set('n', '<leader>gp', '<cmd>Neogit pull<cr>', { desc = 'Neogit Pull' })
  vim.keymap.set('n', '<leader>gP', '<cmd>Neogit push<cr>', { desc = 'Neogit Push' })
  vim.keymap.set('n', '<leader>gc', '<cmd>Neogit commit<cr>', { desc = 'Neogit Commit' })
  vim.keymap.set('n', '<leader>gl', '<cmd>Neogit log<cr>', { desc = 'Neogit Log' })

  vim.keymap.set('n', '<leader>gd', function()
    local lib = require('diffview.lib')
    local view = lib.get_current_view()
    if view then
      vim.cmd('DiffviewClose')
    else
      vim.cmd('DiffviewOpen')
    end
  end, { desc = 'Toggle Diffview' })
end

return M
