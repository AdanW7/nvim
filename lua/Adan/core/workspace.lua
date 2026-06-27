local M = {}

---Returns the workspace root for the current tab.
---@return string
function M.root()
  return vim.fn.getcwd()
end

---Sets the workspace root for the current tab via :tcd.
---@param dir? string  Absolute path. If nil, prompts the user.
function M.set_root(dir)
  if not dir or dir == '' then
    dir = vim.fn.input('Workspace root: ', vim.fn.getcwd(), 'dir')
  end
  if not dir or dir == '' then
    return
  end
  dir = vim.fn.fnamemodify(dir, ':p'):gsub('[/\\]$', '')
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify('Not a directory: ' .. dir, vim.log.levels.ERROR)
    return
  end
  vim.cmd.tcd(dir)
  vim.notify('Tab root → ' .. dir, vim.log.levels.INFO)
end

---Opens a new tab and immediately prompts for its workspace root.
function M.new_tab_with_root()
  vim.cmd('tabnew')
  M.set_root()
end

return M
