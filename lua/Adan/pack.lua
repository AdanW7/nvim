local modules = {
  ui = {
    'Adan.plugins.helix',
    'Adan.plugins.which_key',
    'Adan.plugins.tabline',
    'Adan.plugins.todo',
  },

  collection = {
    'Adan.plugins.mini',
    'Adan.plugins.snacks',
  },

  completion = {
    'Adan.plugins.blink',
  },

  lsp = {
    'Adan.plugins.lsp',
    'Adan.plugins.lazydev',
    'Adan.plugins.conform',
    -- 'Adan.plugins.dap.bootstrap',
  },

  navigation = {
    'Adan.plugins.telescope',
    'Adan.plugins.scope',
    'Adan.plugins.multi',
    'Adan.plugins.oil',
    'Adan.plugins.origami',
  },

  git = {
    'Adan.plugins.gitsigns',
    'Adan.plugins.neogit',
  },
  builtins = { 'Adan.plugins.builtins' },
}

local function setup(module_name)
  local ok, module = pcall(require, module_name)
  if not ok then
    vim.notify(('Failed to load %s: %s'):format(module_name, module), vim.log.levels.ERROR)
    return
  end

  if type(module.setup) == 'function' then
    local ok_setup, err = pcall(module.setup)
    if not ok_setup then
      vim.notify(('Failed to setup %s: %s'):format(module_name, err), vim.log.levels.ERROR)
    end
  end
end

for _, group in pairs(modules) do
  for _, module in ipairs(group) do
    setup(module)
  end
end

--- lazy load context
local context_loaded = false
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    if context_loaded then
      return
    end
    -- Skip non-code buffers
    local ft = vim.bo[args.buf].filetype
    if ft == '' or ft == 'snacks_dashboard' or ft == 'alpha' then
      return
    end
    context_loaded = true
    setup('Adan.plugins.context')
  end,
})

vim.g.adan_pack_plugin_count = #vim.pack.get()
