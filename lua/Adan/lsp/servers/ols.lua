---@brief
---
--- https://github.com/DanielGavin/ols
---
--- `Odin Language Server`.

---@type vim.lsp.Config
return {
  cmd = { 'ols' },
  filetypes = { 'odin' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(fname, { 'ols.json', '.git' })
      or vim.fs.dirname(vim.fs.find(function(name)
        return name:match('%.odin$') ~= nil
      end, {
        path = fname,
        upward = true,
      })[1])
    on_dir(root)
  end,
}
