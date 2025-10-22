local M = {}

function M.extend_opts(opts)
  opts.indent = {
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
  }
end

return M
