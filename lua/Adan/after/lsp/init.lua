---@type vim.lsp.Config
local pyrefly_config = {
  settings = {
    python = {
      pyrefly = {
        displayTypeErrors = 'force-on',
      },
    },
  },
}

vim.lsp.config('pyrefly', pyrefly_config)

local ruff_config = {
  settings = {
    ['indent-width'] = 4,
    ['line-length'] = 120,
    ['target-version'] = 'py311',
    format = {
      preview = true,
    },
    lint = {
      fixable = { 'ALL' },
      ignore = { 'E501', 'F403', 'F405' },
      preview = true,
      select = { 'E4', 'E7', 'E9', 'F', 'B' },
    },
  },
}

vim.lsp.config('pyrefly', pyrefly_config)
vim.lsp.config('ruff', ruff_config)
