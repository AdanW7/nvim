local diagnostic_signs = {
  [vim.diagnostic.severity.ERROR] = '',
  [vim.diagnostic.severity.WARN] = '',
  [vim.diagnostic.severity.INFO] = '',
  [vim.diagnostic.severity.HINT] = '󰌵',
}

vim.diagnostic.config({
  virtual_text = false,
  signs = {
    text = diagnostic_signs,
  },
  virtual_lines = {
    current_line = true,
  },
  underline = true,
  severity_sort = true,
})
