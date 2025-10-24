---@type vim.lsp.Config
return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zon' },
  root_markers = { 'build.zig.zon', 'build.zig', '.git' },
  workspace_required = false,
}
