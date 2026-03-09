---@type LazySpec
return {
  'snacks.nvim', -- only the name of the plugin needs to be specified since it already exists
  opts = {
    indent = {
      indent = {
        enabled = false,
        char = '▎',
        only_scope = true,
        only_current = true,
      },
      scope = {
        char = '▎',
        only_current = true,
      },
      animate = {
        enabled = true,
        duration = {
          step = 8,
          total = 120,
        },
      },
    },
  },
}
