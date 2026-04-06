local M = {}

function M.pre_setup()
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'snacks_dashboard',
    callback = function(args)
      -- Keep dashboard out of tab-scoped buffer sets (scope.nvim).
      vim.bo[args.buf].buflisted = false

      local ok, snacks = pcall(require, 'snacks')
      if not ok then
        return
      end
      for _, picker in ipairs(snacks.picker.get({ source = 'explorer', tab = false })) do
        picker:close()
      end
    end,
  })
end

function M.extend_opts(opts)
  opts.dashboard = {
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
          icon = '󰚰 ',
          key = 'u',
          desc = 'Update Plugins',
          action = function()
            vim.pack.update()
          end,
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
        local count = tonumber(vim.g.adan_pack_plugin_count) or #vim.pack.get()
        return {
          align = 'center',
          text = {
            { 'JADE VIM loaded ', hl = 'footer' },
            { tostring(count), hl = 'special' },
            { ' plugins', hl = 'footer' },
          },
        }
      end,
    },
  }
end

return M
