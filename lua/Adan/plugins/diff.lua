local M = {}

function M.setup()
  vim.pack.add({ 'https://github.com/sindrets/diffview.nvim' }, { load = true, confirm = false })
  require('diffview').setup({
    enhanced_diff_hl = true,
    view = {
      default = { layout = 'diff2_horizontal', winbar_info = true },
      merge_tool = {
        layout = 'diff3_mixed',
        disable_diagnostics = true,
        winbar_info = true,
      },
      file_history = { layout = 'diff2_horizontal', winbar_info = true },
    },
    file_panel = {
      listing_style = 'tree',
      tree_options = { flatten_dirs = true, folder_statuses = 'only_folded' },
      win_config = { position = 'left', width = 32 },
    },
    keymaps = {
      view = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
        { 'n', '<leader>e', '<cmd>DiffviewToggleFiles<cr>', { desc = 'Toggle file panel' } },
      },
      file_panel = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
      },
      file_history_panel = {
        { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
      },
    },
  })
end
return M
