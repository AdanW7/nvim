local group = vim.api.nvim_create_augroup('AdanLspAutocmds', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client == nil then
      return
    end
    if client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end
  end,
  desc = 'LSP: Disable hover capability from Ruff',
})

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'zsl',
  callback = function()
    vim.lsp.start({
      name = 'ZSL LSP',
      cmd = { 'zsl', 'lsp' },
      root_dir = vim.loop.cwd(),
      flags = { exit_timeout = 1000 },
    })
  end,
})
