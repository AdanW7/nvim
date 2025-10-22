local ok, wf = pcall(require, 'vim.lsp._watchfiles')
if ok then
  -- Disable watching for Windows Defender directories
  local original_create = wf._create
  wf._create = function(path, opts, callback)
    if path:match('Windows Defender') or path:match('ProgramData/Microsoft') then
      return { cancel = function() end }
    end
    return original_create(path, opts, callback)
  end
end
