local M = {}

---@return lsp.ClientCapabilities
function M.get()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_blink, blink = pcall(require, 'blink.cmp')
  if ok_blink and type(blink.get_lsp_capabilities) == 'function' then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end
  return capabilities
end

return M
