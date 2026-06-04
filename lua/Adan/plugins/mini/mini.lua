local M = {}
function M.setup()
  vim.pack.add({
    { src = 'https://github.com/echasnovski/mini.nvim', version = 'stable' },
  }, { load = true, confirm = false })

  require('mini.ai').setup()
  require('mini.icons').setup()
  require('mini.icons').mock_nvim_web_devicons()
  require('mini.pairs').setup()

  vim.keymap.set('n', 's', '<Nop>', { noremap = true })
  require('mini.surround').setup({
    respect_selection_type = true,
  })
  require('mini.cursorword').setup({ delay = 100 })
  require('mini.jump').setup({
    mappings = {
      repeat_jump = '', -- disable repeat
    },
    delay = {
      idle_stop = 1, -- stop immediately after jump
    },
  })

  require('mini.statusline').setup({
    content = {
      active = function()
        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
        local git = MiniStatusline.section_git({ trunc_width = 75 })
        local diff = MiniStatusline.section_diff({ trunc_width = 75 })
        local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
        local filename = MiniStatusline.section_filename({ trunc_width = 140 })
        local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
        local location = MiniStatusline.section_location({ trunc_width = 75 })

        return MiniStatusline.combine_groups({
          { hl = mode_hl, strings = { mode } },
          { hl = 'MiniStatuslineDevinfo', strings = { git, diff, diagnostics } },
          '%<', -- truncation point
          { hl = 'MiniStatuslineFilename', strings = { filename } },
          '%=', -- right align
          { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
          { hl = mode_hl, strings = { location } },
        })
      end,
    },
  })
end
return M
