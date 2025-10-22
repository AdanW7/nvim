local M = {}

local registry = require('Adan.lsp.registry')

---@param name string
---@return vim.lsp.Config?
local function load_server_config(name)
  local ok, server_config = pcall(require, 'Adan.lsp.servers.' .. name)
  if not ok then
    vim.notify(
      ('Failed to load LSP server config %q: %s'):format(name, server_config),
      vim.log.levels.ERROR
    )
    return nil
  end
  ---@cast server_config vim.lsp.Config
  if type(server_config) ~= 'table' then
    vim.notify(('LSP server config %q did not return a table'):format(name), vim.log.levels.ERROR)
    return nil
  end
  return server_config
end

---@param name string
---@param entry boolean|vim.lsp.Config
---@param capabilities lsp.ClientCapabilities
---@return vim.lsp.Config?
local function configure_server(name, entry, capabilities)
  if entry == false or entry == nil then
    return nil
  end

  ---@type vim.lsp.Config?
  local config
  if entry == true then
    config = load_server_config(name)
  else
    ---@cast entry vim.lsp.Config
    config = entry
  end
  if config == nil then
    return nil
  end

  config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
  vim.lsp.config(name, config)
  return config
end

---@return nil
function M.setup()
  require('Adan.lsp.filetypes').setup()

  local capabilities = require('Adan.lsp.capabilities').get()

  for name, entry in pairs(registry) do
    local config = configure_server(name, entry, capabilities)
    if config then
      vim.lsp.enable(name)
    end
  end
end

return M
