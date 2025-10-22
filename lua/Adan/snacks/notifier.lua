local M = {}

function M.extend_opts(opts)
  opts.notifier = {
    enabled = true,
  }
end

return M
