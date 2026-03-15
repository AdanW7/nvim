---@type Adan.LazySpec
return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  init = function()
    -- Disable netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'snacks_dashboard',
      callback = function()
        local ok, snacks = pcall(require, 'snacks')
        if not ok then
          return
        end
        for _, picker in ipairs(snacks.picker.get({ source = 'explorer', tab = false })) do
          picker:close()
        end
      end,
    })
  end,
  opts = {
    dashboard = {
      enabled = true,
      preset = {
        header = [[
    ░█████    ░███    ░███████   ░██████████    ░██    ░██ ░██████░███     ░███
      ░██    ░██░██   ░██   ░██  ░██            ░██    ░██   ░██  ░████   ░████
      ░██   ░██  ░██  ░██    ░██ ░██            ░██    ░██   ░██  ░██░██ ░██░██
      ░██  ░█████████ ░██    ░██ ░█████████     ░██    ░██   ░██  ░██ ░████ ░██
░██   ░██  ░██    ░██ ░██    ░██ ░██             ░██  ░██    ░██  ░██  ░██  ░██
░██   ░██  ░██    ░██ ░██   ░██  ░██              ░██░██     ░██  ░██       ░██
 ░██████   ░██    ░██ ░███████   ░██████████       ░███    ░██████░██       ░██
]],
        keys = {
          { icon = '󰈞 ', key = 'f', desc = 'Find File', action = ':Telescope find_files' },
          { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
          { icon = '󰋚 ', key = 'r', desc = 'Recent Files', action = ':Telescope oldfiles' },
          { icon = '󰱼 ', key = 'g', desc = 'Find Text', action = ':Telescope live_grep' },
          { icon = ' ', key = 'c', desc = 'Config', action = ':e $MYVIMRC' },
          {
            icon = '󰦛 ',
            key = 's',
            desc = 'Restore Session',
            action = function()
              require('persistence').load()
            end,
          },
          {
            icon = '󰒲 ',
            key = 'l',
            desc = 'Lazy',
            action = ':Lazy',
            enabled = package.loaded.lazy ~= nil,
          },
          { icon = '󰩈 ', key = 'q', desc = 'Quit', action = ':qa' },
        },
      },
      sections = {
        { section = 'header' },
        { section = 'keys', gap = 1, padding = 1 },
        {
          icon = ' ',
          title = 'Recent Files',
          section = 'recent_files',
          indent = 2,
          padding = 1,
        },
        { icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
        function()
          local stats = require('lazy.stats').stats()
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          return {
            align = 'center',
            text = {
              { 'JADE VIM loaded ', hl = 'footer' },
              { stats.loaded .. '/' .. stats.count, hl = 'special' },
              { ' plugins in ', hl = 'footer' },
              { ms .. 'ms', hl = 'special' },
            },
          }
        end,
      },
    },
  },
}
