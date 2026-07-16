local M = {}

---@return lsp.ClientCapabilities
function M.get()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- Disable watch-based file notifications (can cause Windows defender issues)
  capabilities.workspace = capabilities.workspace or {}
  capabilities.workspace.didChangeWatchedFiles = capabilities.workspace.didChangeWatchedFiles or {}
  capabilities.workspace.didChangeWatchedFiles.dynamicRegistration = false

  local ok_blink, blink = pcall(require, 'blink.cmp')
  if ok_blink and type(blink.get_lsp_capabilities) == 'function' then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end
  return capabilities
end

return M
