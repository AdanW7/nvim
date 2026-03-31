---@type Adan.LazySpec
return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'ahmedkhalf/project.nvim',
  },
  config = function()
    require('Adan.overrides.telescope')
  end,
}
