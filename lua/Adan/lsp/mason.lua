local M = {}

local loaded = false

local function ensure()
  if loaded then
    return
  end
  loaded = true

  vim.pack.add({
    'https://github.com/mason-org/mason.nvim',
  }, { load = true, confirm = false })

  require('mason').setup()
end

function M.open()
  ensure()
  vim.cmd.Mason()
end

function M.refresh()
  ensure()
  require('mason-registry').refresh()
end

return M
