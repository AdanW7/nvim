---@type vim.lsp.Config
return {
  cmd = { 'jade_toml_lsp' },
  filetypes = { 'toml' },
  root_markers = { 'jade.toml', '.git' },
  settings = {
    jade_toml_lsp = {
      format = {
        enabled = false,
      },
      diagnostics = {
        enabled = false,
      },
      inlayHints = {
        enabled = true,
      },
    },
  },
}
