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
