local modules = {
  ui = {
    'Adan.plugins.helix',
    'Adan.plugins.context',
    'Adan.plugins.which_key',
  },

  git = {
    'Adan.plugins.gitsigns',
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
    -- 'Adan.plugins.dap.bootstrap', # commenting out dap because I find i don't actually use it but im keeping the config code incase i use it in the future
  },

  navigation = {
    'Adan.plugins.telescope',
    'Adan.plugins.scope',
    'Adan.plugins.multi',
    'Adan.plugins.oil',
    'Adan.plugins.origami',
  },
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

-- built in plugins
local builtins = {
  'cfilter',
  'justify',
  'matchit',
  -- 'netrw',
  -- 'nohlsearch',
  'nvim.difftool',
  'nvim.tohtml',
  'nvim.undotree',
  -- 'swapmouse',
  -- 'termdebug',
}
for _, plugin in ipairs(builtins) do
  pcall(vim.cmd.packadd--[[@as function]], plugin)
end

for _, group in pairs(modules) do
  for _, module in ipairs(group) do
    setup(module)
  end
end

vim.g.adan_pack_plugin_count = #vim.pack.get()
