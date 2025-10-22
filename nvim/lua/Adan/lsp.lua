-- vim.lsp.config('pyright', require('Adan.lsp.pyright'))
-- vim.lsp.config('ruff', require('Adan.lsp.ruff'))

-- vim.lsp.enable({
--   "bashls",
--   "clangd",
--   "gopls",
--   "lua_ls",
--   "ruff",
--   "pyright",
--   "texlab",
--   "ts_ls",
--   "rust-analyzer",
--   "zls",
-- })

-- local lsp_configs = {
--   "bashls",
--   "clangd",
--   "gopls",
--   "lua_ls",
--   "ruff",
--   "pyright",
--   "texlab",
--   "ts_ls",
--   "rust_analyzer",
--   "zls",
--   -- Add more here as you create config files
-- }
-- for _, lsp_name in ipairs(lsp_configs) do
--   vim.lsp.config(lsp_name, require('Adan.lsp.' .. lsp_name))
-- end

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "python",
--   callback = function()
--     print("Python filetype detected")
--     print("Active clients: " .. vim.inspect(vim.lsp.get_clients()))
--   end,
-- })
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
