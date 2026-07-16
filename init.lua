if vim.loader then
	vim.loader.enable()
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_matchit = 1
vim.g.loaded_man = 1
vim.g.loaded_remote_plugins = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_gzip = 1

require('Adan')

-- =============================================================================
-- enable ui2 mode
-- =============================================================================
require('vim._core.ui2').enable()
