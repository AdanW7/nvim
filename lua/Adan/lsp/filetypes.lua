local M = {}

M.extension_filetypes = {
  gotmpl = 'gotmpl',
  mdx = 'markdown.mdx',
  powershell = 'powershell',
  psd1 = 'psd1',
  psm1 = 'psm1',
  xsl = 'xsl',
}

M.pattern_filetypes = {
  ['.*/%.gitlab%-ci%.ya?ml'] = 'yaml.gitlab',
  ['.*/docker%-compose%.ya?ml'] = 'yaml.docker-compose',
  ['.*/compose%.ya?ml'] = 'yaml.docker-compose',
  ['.*/values%.ya?ml'] = 'yaml.helm-values',
  ['.*/values%..*%.ya?ml'] = 'yaml.helm-values',
}

---@return nil
function M.setup()
  vim.filetype.add({
    extension = M.extension_filetypes,
    pattern = M.pattern_filetypes,
  })
end

return M
