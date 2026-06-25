local M = {}

local builtins = {
  'cfilter',
  'justify',
  'matchit',
  -- 'netrw',
  -- 'nohlsearch',
  'nvim.difftool',
  'nvim.tohtml',
  'nvim.undotree',
  -- 'swapmouse',
  -- 'termdebug',
}

function M.setup()
  for _, plugin in ipairs(builtins) do
    pcall(vim.cmd.packadd--[[@as function]], plugin)
  end
end

return M
