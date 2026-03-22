---@type Adan.LazySpec

return {
  'xzbdmw/colorful-menu.nvim',
  config = function()
    require('colorful-menu').setup({
      ls = {
        lua_ls = {
          arguments_hl = 'ColorfulMenuDim',
        },
        pylsp = {
          extra_info_hl = 'ColorfulMenuDim',
          arguments_hl = 'ColorfulMenuArgs',
        },
        fallback = true,
        fallback_extra_info_hl = 'ColorfulMenuDim',
      },
      fallback_highlight = '@variable',
      max_width = 60,
    })
  end,
}
