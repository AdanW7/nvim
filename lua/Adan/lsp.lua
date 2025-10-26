
local lsp_dir = vim.fn.stdpath('config') .. '/lua/Adan/lsp'
local lsp_files = vim.fn.glob(lsp_dir .. '/*.lua', false, true)

local loaded_lsps = {}
local failed_lsps = {}

-- Load each LSP config
for _, filepath in ipairs(lsp_files) do
  -- Extract LSP name from filename (e.g., "lua_ls.lua" -> "lua_ls")
  local lsp_name = vim.fn.fnamemodify(filepath, ':t:r')

  -- Try to load the config
  local ok, config = pcall(require, 'Adan.lsp.' .. lsp_name)
  if ok then
    vim.lsp.config(lsp_name, config)
    table.insert(loaded_lsps, lsp_name)
  else
    table.insert(failed_lsps, lsp_name)
    vim.notify('Failed to load config for ' .. lsp_name .. ': ' .. tostring(config), vim.log.levels.WARN)
  end
end

-- Enable all successfully loaded LSPs
if #loaded_lsps > 0 then
  vim.lsp.enable(loaded_lsps)
  vim.notify('Loaded ' .. #loaded_lsps .. ' LSP(s): ' .. table.concat(loaded_lsps, ', '), vim.log.levels.INFO)
end

-- Report failures
if #failed_lsps > 0 then
  vim.notify('Failed to load ' .. #failed_lsps .. ' LSP(s): ' .. table.concat(failed_lsps, ', '), vim.log.levels.ERROR)
end
