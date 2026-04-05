local M = {}

function M.extend_opts(opts)
  opts.explorer = {
    enabled = true,
    auto_close = true,
    hidden = true,
    git_icons = true,
  }
end

function M.keys()
  return {
    {
      lhs = '<leader>e',
      rhs = function()
        Snacks.explorer()
      end,
      desc = 'Explorer',
    },
    {
      lhs = '<leader>E',
      rhs = function()
        Snacks.explorer({ cwd = vim.fn.expand('%:p:h') })
      end,
      desc = 'Explorer (cwd)',
    },
  }
end

return M
