-- Compatibility shim for plugins still using deprecated `vim.lsp.buf_get_clients`.
if vim.lsp and vim.lsp.get_clients and vim.lsp.buf_get_clients then
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf_get_clients = function(arg)
    ---@type vim.lsp.get_clients.Filter
    local opts = {}
    if type(arg) == 'number' then
      opts.bufnr = arg
    elseif type(arg) == 'table' then
      opts = vim.deepcopy(arg)
    end

    local list = vim.lsp.get_clients(opts)
    local by_id = {} ---@type table<integer, vim.lsp.Client>
    for _, client in ipairs(list) do
      by_id[client.id] = client
    end
    return by_id
  end
end
