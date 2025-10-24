local custom_lsps = {
  "bashls",
  "clangd",
  "gopls",
  "lua_ls",
  "ruff",
  "pyright",
  "texlab",
  "ts_ls",
  "rust_analyzer",
  "zls",
}

local default_lsps = {}

-- Enable all LSPs
local all_lsps = vim.list_extend(vim.deepcopy(custom_lsps), default_lsps)

-- Load custom configs
for _, lsp_name in ipairs(custom_lsps) do
  local ok, config = pcall(require, 'Adan.lsp.' .. lsp_name)
  if ok then
    vim.lsp.config(lsp_name, config)
  else
    vim.notify('Failed to load config for ' .. lsp_name, vim.log.levels.WARN)
  end
end
vim.lsp.enable(all_lsps)
