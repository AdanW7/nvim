---@type Adan.LazySpec
return {
  'snacks.nvim', -- only the name of the plugin needs to be specified since it already exists
  opts = {
    indent = {
      indent = {
        enabled = false,
        char = '▏',
        only_scope = true,
        only_current = true,
        hl = 'SnacksIndent',
      },
      scope = {
        char = '▏',
        only_current = true,
        hl = 'SnacksIndentScope',
      },
      animate = {
        enabled = true,
        duration = {
          step = 4,
          total = 80,
        },
      },
    },
  },
}
