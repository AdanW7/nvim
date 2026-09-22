---@brief
---
--- https://github.com/nim-lang/langserver
---
---
--- `nim-langserver` can be installed via the `nimble` package manager:
--- ```sh
--- nimble install nimlangserver
--- ```

---@type vim.lsp.Config
return {
  cmd = { 'nimlangserver' },
  filetypes = { 'nim' },
  root_markers = { '*.nimble', '.git' },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, function(name)
      return name:match('%.nimble$') ~= nil or name == '.git'
    end)
    if root then
      on_dir(root)
    end
  end,
}
