local M = {}

local function load_neogit()
  if package.loaded['neogit'] then
    return
  end

  vim.pack.add({
    'https://github.com/neogitorg/neogit',
  }, { load = true, confirm = false })

  require('neogit').setup({
    kind = 'vsplit',
    disable_hint = false,
    disable_signs = false,
    disable_insert_on_commit = 'auto',
    graph_style = 'unicode',
    commit_editor = {
      kind = 'vsplit',
    },
    commit_select_view = {
      kind = 'vsplit',
    },
    log_view = {
      kind = 'vsplit',
    },
    status = {
      recent_commit_count = 30,
    },
  })
end

---Neogit command wrapper: ensures neogit is loaded before opening.
---@param args? table
local function open(args)
  return function()
    load_neogit()
    require('neogit').open(args)
  end
end

function M.setup()
  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc })
  end

  map('<leader>gN', open(), 'Neogit: status')
  map('<leader>gnc', open({ 'commit' }), 'Neogit: commit')
  map('<leader>gnp', open({ 'pull' }), 'Neogit: pull')
  map('<leader>gnP', open({ 'push' }), 'Neogit: push')
  map('<leader>gnl', open({ 'log' }), 'Neogit: log')
  map('<leader>gnb', open({ 'branch' }), 'Neogit: branch')
  map('<leader>gns', open({ 'stash' }), 'Neogit: stash')

  map('<leader>gnf', function()
    load_neogit()
    require('neogit').open({ cwd = vim.fn.expand('%:p:h') })
  end, 'Neogit: status in buffer dir')
end

return M
