local M = {}

function M.extend_opts(opts)
  opts.lazygit = {
    enabled = true,
    configure = true,
  }
end

function M.keys()
  return {
    {
      lhs = '<leader>gg',
      rhs = function()
        Snacks.lazygit()
      end,
      desc = 'LazyGit',
    },
    {
      lhs = '<leader>gG',
      rhs = function()
        Snacks.lazygit.log()
      end,
      desc = 'LazyGit Log',
    },
    {
      lhs = '<leader>gbh',
      rhs = function()
        Snacks.lazygit.log_file()
      end,
      desc = 'LazyGit Current File History',
    },
  }
end

return M
