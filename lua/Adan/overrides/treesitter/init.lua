require('nvim-treesitter').setup {}

require('nvim-treesitter').install {
  'bash',
  'bibtex',
  'c',
  'cmake',
  'cpp',
  'git_config',
  'git_rebase',
  'gitattributes',
  -- 'gitcommit', -- this causes error on windows currently
  'gitignore',
  'http',
  'latex',
  'lua',
  'javascript',
  'markdown',
  'markdown_inline',
  'odin',
  'powershell',
  'python',
  'query',
  'rust',
  'toml',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
  'zig',
}

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    local ok = pcall(vim.treesitter.start)
    if ok then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require('treesitter-context').setup {
  max_lines = 5,
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 10,
  trim_scope = 'outer',
  mode = 'cursor',
}

require('nvim-treesitter-textobjects').setup {
  select = { lookahead = true },
  move = { set_jumps = true },
}

local select = require('nvim-treesitter-textobjects.select')
local move = require('nvim-treesitter-textobjects.move')
local swap = require('nvim-treesitter-textobjects.swap')

-- Select
local select_keymaps = {
  ['af'] = { '@function.outer', 'Around function' },
  ['if'] = { '@function.inner', 'Inside function' },
  ['ac'] = { '@class.outer', 'Around class' },
  ['ic'] = { '@class.inner', 'Inside class' },
  ['ai'] = { '@conditional.outer', 'Around conditional' },
  ['ii'] = { '@conditional.inner', 'Inside conditional' },
  ['al'] = { '@loop.outer', 'Around loop' },
  ['il'] = { '@loop.inner', 'Inside loop' },
  ['aa'] = { '@parameter.outer', 'Around parameter' },
  ['ia'] = { '@parameter.inner', 'Inside parameter' },
  ['a/'] = { '@comment.outer', 'Around comment' },
  ['i/'] = { '@comment.inner', 'Inside comment' },
  ['ab'] = { '@block.outer', 'Around block' },
  ['ib'] = { '@block.inner', 'Inside block' },
  ['aC'] = { '@call.outer', 'Around call' },
  ['iC'] = { '@call.inner', 'Inside call' },
  ['aT'] = { '@type.outer', 'Around type' },
  ['iT'] = { '@type.inner', 'Inside type' },
}
for lhs, v in pairs(select_keymaps) do
  local query, desc = v[1], v[2]
  vim.keymap.set({ 'x', 'o' }, lhs, function()
    select.select_textobject(query, 'textobjects')
  end, { desc = desc })
end

-- Move
local move_keymaps = {
  { ']f', 'goto_next_start', '@function.outer', 'Next function start' },
  { ']c', 'goto_next_start', '@class.outer', 'Next class start' },
  { ']a', 'goto_next_start', '@parameter.inner', 'Next parameter start' },
  { ']F', 'goto_next_end', '@function.outer', 'Next function end' },
  { ']C', 'goto_next_end', '@class.outer', 'Next class end' },
  { ']A', 'goto_next_end', '@parameter.inner', 'Next parameter end' },
  { '[f', 'goto_previous_start', '@function.outer', 'Prev function start' },
  { '[c', 'goto_previous_start', '@class.outer', 'Prev class start' },
  { '[a', 'goto_previous_start', '@parameter.inner', 'Prev parameter start' },
  { '[F', 'goto_previous_end', '@function.outer', 'Prev function end' },
  { '[C', 'goto_previous_end', '@class.outer', 'Prev class end' },
  { '[A', 'goto_previous_end', '@parameter.inner', 'Prev parameter end' },
}
for _, m in ipairs(move_keymaps) do
  local lhs, fn, query, desc = m[1], m[2], m[3], m[4]
  vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
    move[fn](query, 'textobjects')
  end, { desc = desc })
end

-- Swap
vim.keymap.set('n', '<leader>a', function()
  swap.swap_next('@parameter.inner')
end, { desc = 'Swap next parameter' })
vim.keymap.set('n', '<leader>A', function()
  swap.swap_previous('@parameter.inner')
end, { desc = 'Swap previous parameter' })

-- custom tree sitter setup
local ext = (jit.os == 'Windows') and 'dll' or 'so'
local so = vim.fn.stdpath('data') .. '/parsers/zsl/parser.' .. ext

if vim.fn.filereadable(so) == 0 then
  vim.fn.mkdir(vim.fn.fnamemodify(so, ':h'), 'p')
  local src = vim.fn.stdpath('config') .. '/parsers/zsl/src/parser.c'

  local result = vim.system({ 'cc', '-shared', '-fPIC', '-o', so, src }, { text = true }):wait()

  if result.code ~= 0 then
    vim.notify('ZSL parser compile failed:\n' .. (result.stderr or ''), vim.log.levels.ERROR)
    return
  end
end

vim.treesitter.language.add('zsl', { path = so })
vim.treesitter.language.register('zsl', 'zsl')
vim.filetype.add({
  extension = { zsl = 'zsl' },
})
