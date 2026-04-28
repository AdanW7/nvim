local modules = {
  -- theme plugins
  'Adan.plugins.theme.helix',
  'Adan.plugins.theme.tree_sitter',
  'Adan.plugins.theme.bufferline',
  'Adan.plugins.theme.lualine',
  'Adan.plugins.markdown.render-markdown',

  -- keybinds
  'Adan.plugins.keybinds.which_key',

  -- snacks
  'Adan.plugins.snacks.snacks',

  -- completion
  'Adan.plugins.completion.colorful-menu',
  'Adan.plugins.completion.blink',
  'Adan.plugins.snippets.luasnip',

  -- lsp / dap
  'Adan.plugins.lsp.lsp',
  'Adan.plugins.formatting.conform',
  -- 'Adan.plugins.dap.bootstrap', # commenting out dap because I find i don't actually use it but im keeping the config code incase i use it in the future

  -- navigation plugins
  'Adan.plugins.navigation.telescope',
  'Adan.plugins.navigation.scope',
  'Adan.plugins.navigation.project',
  'Adan.plugins.navigation.persistence',
  'Adan.plugins.navigation.multi',
  'Adan.plugins.navigation.oil',
  'Adan.plugins.navigation.origami',

  -- git plugins
  'Adan.plugins.git.gitsigns',

  -- mini
  'Adan.plugins.mini.mini',
}

local function safe_setup(module_name)
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
pcall(vim.cmd, 'packadd nvim.undotree')
pcall(vim.cmd, 'packadd nvim.difftool')

for _, module_name in ipairs(modules) do
  safe_setup(module_name)
end

vim.g.adan_pack_plugin_count = #vim.pack.get()
