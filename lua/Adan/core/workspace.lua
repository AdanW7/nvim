local M = {}

function M.root()
  return vim.fn.getcwd()
end

---@param dir? string
---@param name? string  Optional display name for the tab pill. Defaults to dirname.
function M.set_root(dir, name)
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

  if name and name ~= '' then
    vim.t.tab_name = name
  else
    vim.t.tab_name = nil
  end

  vim.notify('Tab root → ' .. dir, vim.log.levels.INFO)
end

function M.new_tab_with_root()
  vim.cmd('tabnew')
  M.set_root()
end

return M
