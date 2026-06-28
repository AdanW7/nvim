-- =============================================================================
-- LEADER KEY SETUP
-- =============================================================================
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- =============================================================================
-- BASIC EDITOR BEHAVIOR
-- =============================================================================

-- Clear search highlights
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Redo with capital U
vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- =============================================================================
-- MOVEMENT & NAVIGATION
-- =============================================================================

-- Line navigation
vim.keymap.set({ 'n', 'v', 'o', 'x' }, 'gh', '0', { desc = 'go to beginning of line' })
vim.keymap.set({ 'n', 'v', 'o', 'x' }, 'gs', '^', { desc = 'go to first not white space in line' })
vim.keymap.set({ 'n', 'v', 'o', 'x' }, 'gl', '$', { desc = 'go to end of line' })
vim.keymap.set({ 'n', 'v', 'o', 'x' }, 'ge', 'G', { desc = 'go to end of file' })

-- Page navigation (centered)
vim.keymap.set({ 'n', 'v' }, '<C-d>', '<C-d>zz', { desc = 'Scroll down (centered)' })
vim.keymap.set({ 'n', 'v' }, '<C-u>', '<C-u>zz', { desc = 'Scroll up (centered)' })

-- =============================================================================
-- SEARCH
-- =============================================================================

-- Search within visual selection
vim.keymap.set('v', '/', function()
  vim.cmd('normal! "vy')
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>/\\%V', true, false, true), 'n', false)
end, { desc = 'Search in visual selection' })

-- =============================================================================
-- COPY, PASTE & CLIPBOARD
-- =============================================================================

-- System clipboard operations (Leader prefix)
vim.keymap.set({ 'n', 'v' }, '<Leader>y', [["+y]], { desc = 'save text to system clipboard' })
vim.keymap.set({ 'n' }, '<Leader>ys', function()
  vim.fn.setreg('+', vim.v.servername)
end, { desc = 'Copy servername to clipboard' })

vim.keymap.set('n', '<Leader>Y', [["+Y]], { desc = 'save current line to system clipboard' })
vim.keymap.set('n', '<Leader>pp', [["+p]], { desc = 'paste from system clipboard at cursor' })
vim.keymap.set('n', '<Leader>pP', [["+P]], { desc = 'paste from system clipboard before cursor' })

-- Replace selection without yanking
vim.keymap.set({ 'v', 'x' }, 'R', [["_dP]], { desc = 'Replace selection with unnamed register' })
vim.keymap.set(
  { 'v', 'x' },
  '<Leader>R',
  [["+p]],
  { desc = 'Replace selection with system clipboard' }
)

-- =============================================================================
-- WINDOW TRANSPOSE + DIRECTIONAL SWAP
-- =============================================================================

local function adjacent_winid(dir)
  local cur_nr = vim.fn.winnr()
  local nr = vim.fn.winnr(dir)
  if nr == cur_nr then
    return nil
  end
  return vim.fn.win_getid(nr)
end

local function swap_windows(win_a, win_b)
  if not win_a or not win_b then
    return false
  end

  local buf_a = vim.api.nvim_win_get_buf(win_a)
  local buf_b = vim.api.nvim_win_get_buf(win_b)
  local cur_a = vim.api.nvim_win_get_cursor(win_a)
  local cur_b = vim.api.nvim_win_get_cursor(win_b)

  vim.api.nvim_win_set_buf(win_a, buf_b)
  vim.api.nvim_win_set_buf(win_b, buf_a)

  pcall(vim.api.nvim_win_set_cursor, win_a, cur_b)
  pcall(vim.api.nvim_win_set_cursor, win_b, cur_a)
  return true
end

local function swap_with_direction(dir)
  local cur = vim.api.nvim_get_current_win()
  local target = adjacent_winid(dir)
  if not target then
    vim.notify('No adjacent window in that direction', vim.log.levels.WARN)
    return
  end
  swap_windows(cur, target)
end

-- True transpose: flip orientation of current+adjacent pair
local function transpose_pair_orientation()
  local cur = vim.api.nvim_get_current_win()
  local target = adjacent_winid('l')
    or adjacent_winid('h')
    or adjacent_winid('j')
    or adjacent_winid('k')
  if not target then
    vim.notify('No adjacent window to transpose', vim.log.levels.WARN)
    return
  end

  local p1 = vim.api.nvim_win_get_position(cur)
  local p2 = vim.api.nvim_win_get_position(target)
  local side_by_side = (p1[1] == p2[1])

  local cur_buf = vim.api.nvim_win_get_buf(cur)
  local tgt_buf = vim.api.nvim_win_get_buf(target)
  local cur_pos = vim.api.nvim_win_get_cursor(cur)
  local tgt_pos = vim.api.nvim_win_get_cursor(target)

  local before = vim.api.nvim_tabpage_list_wins(0)
  vim.api.nvim_set_current_win(target)
  if side_by_side then
    vim.cmd('split')
  else
    vim.cmd('vsplit')
  end

  local after = vim.api.nvim_tabpage_list_wins(0)
  local seen, new_win = {}, nil
  for _, w in ipairs(before) do
    seen[w] = true
  end
  for _, w in ipairs(after) do
    if not seen[w] then
      new_win = w
      break
    end
  end
  if not new_win then
    vim.notify('Failed to create transposed window', vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_win_set_buf(target, tgt_buf)
  vim.api.nvim_win_set_buf(new_win, cur_buf)
  pcall(vim.api.nvim_win_close, cur, false)

  pcall(vim.api.nvim_win_set_cursor, target, tgt_pos)
  pcall(vim.api.nvim_win_set_cursor, new_win, cur_pos)
  vim.api.nvim_set_current_win(new_win)
end

vim.keymap.set(
  'n',
  '<leader>wt',
  transpose_pair_orientation,
  { desc = 'Transpose pair orientation (left/right <-> top/bottom)' }
)

vim.keymap.set('n', '<leader>wH', function()
  swap_with_direction('h')
end, { desc = 'Swap with left window' })

vim.keymap.set('n', '<leader>wL', function()
  swap_with_direction('l')
end, { desc = 'Swap with right window' })

vim.keymap.set('n', '<leader>wJ', function()
  swap_with_direction('j')
end, { desc = 'Swap with lower window' })

vim.keymap.set('n', '<leader>wK', function()
  swap_with_direction('k')
end, { desc = 'Swap with upper window' })

-- =============================================================================
-- WINDOW MANAGEMENT
-- =============================================================================

-- Window splits
vim.keymap.set(
  'n',
  '<Leader>wv',
  '<cmd>vsplit<CR>',
  { silent = true, desc = 'Split Window vertically' }
)
vim.keymap.set(
  'n',
  '<Leader>ws',
  '<cmd>split<CR>',
  { silent = true, desc = 'Split Window horizontally' }
)

-- Window navigation
vim.keymap.set('n', '<Leader>wh', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<Leader>wl', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<Leader>wj', '<C-w>j', { desc = 'Move to window below' })
vim.keymap.set('n', '<Leader>wk', '<C-w>k', { desc = 'Move to window above' })

-- Window close
vim.keymap.set(
  'n',
  '<Leader>wq',
  '<cmd>close<CR>',
  { silent = true, desc = 'Close current window' }
)
vim.keymap.set(
  'n',
  '<Leader>wo',
  '<cmd>only<CR>',
  { silent = true, desc = 'Window: close all but current' }
)

-- Scratch buffers
vim.keymap.set('n', '<leader>wnv', function()
  vim.cmd('vnew')
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'hide'
  vim.bo.swapfile = false
end, { desc = 'New scratch buffer (vertical)' })

vim.keymap.set('n', '<leader>wns', function()
  vim.cmd('new')
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'hide'
  vim.bo.swapfile = false
end, { desc = 'New scratch buffer (horizontal)' })

-- =============================================================================
-- TAB MANAGEMENT
-- =============================================================================

-- Tab creation
vim.keymap.set({ 'n', 't' }, '<Leader>ta', '<cmd>tabnew<CR>', { silent = true, desc = 'Tab: new' })
vim.keymap.set(
  { 'n', 't' },
  '<Leader>tb',
  '<cmd>tabedit %<CR>',
  { silent = true, desc = 'Tab: buffer in new tab' }
)
vim.keymap.set('n', '<leader>td', '<cmd>ScopeDuplicateTab<cr>', { desc = 'Tab: Duplicate' })

-- Tab closing
vim.keymap.set(
  { 'n', 't' },
  '<Leader>tcc',
  '<cmd>tabclose<CR>',
  { silent = true, desc = 'Tab: close current' }
)
vim.keymap.set(
  { 'n', 't' },
  '<Leader>tco',
  '<cmd>tabonly<CR>',
  { silent = true, desc = 'Tab: close others' }
)

-- Tab navigation
vim.keymap.set({ 'n', 't' }, '<Leader>t1', '1gt', { desc = 'Tab: go to 1' })
vim.keymap.set({ 'n', 't' }, '<Leader>t2', '2gt', { desc = 'Tab: go to 2' })
vim.keymap.set({ 'n', 't' }, '<Leader>t3', '3gt', { desc = 'Tab: go to 3' })

-- Tab reordering
vim.keymap.set(
  { 'n', 't' },
  '<Leader>tm>',
  '<cmd>tabmove +1<CR>',
  { silent = true, desc = 'Tab: move right' }
)
vim.keymap.set(
  { 'n', 't' },
  '<Leader>tm<',
  '<cmd>tabmove -1<CR>',
  { silent = true, desc = 'Tab: move left' }
)

vim.keymap.set({ 'n', 't' }, '<Leader>tw', function()
  require('Adan.core.workspace').set_root()
end, { silent = true, desc = 'Tab: set workspace root' })

vim.keymap.set({ 'n', 't' }, '<Leader>tn', function()
  require('Adan.core.workspace').new_tab_with_root()
end, { silent = true, desc = 'Tab: new tab + set workspace root' })

vim.keymap.set({ 'n', 't' }, '<Leader>tr', function()
  local name = vim.fn.input('Tab name: ', vim.t.tab_name or '')
  if name ~= '' then
    vim.t.tab_name = name
    vim.cmd.redrawtabline()
  end
end, { silent = true, desc = 'Tab: rename' })

vim.keymap.set('n', '<leader>tt', function()
  vim.g.tabline_disable = not vim.g.tabline_disable
  -- Force a redraw so the tabline updates immediately
  vim.cmd('redrawtabline')
end, { desc = 'Tab: Toggle tabline' })
-- =============================================================================
-- TERMINAL MODE
-- =============================================================================

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal window navigation
vim.keymap.set('t', '<A-h>', '<C-\\><C-n><C-w>h', { desc = 'Exit terminal to left split' })
vim.keymap.set('t', '<A-j>', '<C-\\><C-n><C-w>j', { desc = 'Exit terminal to lower split' })
vim.keymap.set('t', '<A-k>', '<C-\\><C-n><C-w>k', { desc = 'Exit terminal to above split' })
vim.keymap.set('t', '<A-l>', '<C-\\><C-n><C-w>l', { desc = 'Exit terminal to right split' })

-- =============================================================================
-- QUICKFIX LIST
-- =============================================================================

-- Quickfix history
vim.keymap.set('n', '<leader>qp', '<cmd>colder<CR>', { desc = 'Older quickfix list' })
vim.keymap.set('n', '<leader>qn', '<cmd>cnewer<CR>', { desc = 'Newer quickfix list' })

-- Quickfix window
vim.keymap.set('n', '<leader>qo', '<cmd>copen<CR>', { desc = 'Open quickfix list' })
vim.keymap.set('n', '<leader>qc', '<cmd>cclose<CR>', { desc = 'Close quickfix list' })

-- =============================================================================
-- DIAGNOSTICS
-- =============================================================================

vim.keymap.set('n', '<leader>qd', function()
  vim.diagnostic.setqflist()
end, { desc = 'Diagnostics to quickfix list' })

-- =============================================================================
-- LSP
-- =============================================================================
vim.keymap.set('n', 'gd', function()
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    vim.lsp.buf.definition()
  else
    vim.cmd('normal! gd')
  end
end, { desc = 'Go to definition' })

vim.keymap.set('n', 'gD', function()
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    vim.lsp.buf.declaration()
  else
    vim.cmd('normal! gD')
  end
end, { desc = 'Go to declaration' })

vim.keymap.set('n', '<leader>lh', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = 'Toggle inlay hints' })

-- LSP restart
vim.keymap.set('n', '<leader>lr', function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local names = {}
  for _, client in ipairs(clients) do
    if not vim.tbl_contains(names, client.name) then
      table.insert(names, client.name)
    end
  end
  for _, name in ipairs(names) do
    vim.lsp.enable(name, false)
    vim.lsp.enable(name, true)
  end
  vim.notify('LSP restarted: ' .. table.concat(names, ', '), vim.log.levels.INFO)
end, { desc = 'LSP Restart' })

-- =============================================================================
-- FILE & DIRECTORY
-- =============================================================================

-- Change directory to current file
vim.keymap.set('n', '<leader>cd', function()
  local dir = vim.fn.expand('%:p:h')
  vim.fn.chdir(dir)
  vim.notify('cwd: ' .. dir, vim.log.levels.INFO)
end, { desc = 'Change directory to current file' })

-- =============================================================================
-- RELOAD CONFIG
-- =============================================================================

vim.keymap.set('n', '<leader>rc', function()
  -- Clear Lua modules under "Adan"
  for name, _ in pairs(package.loaded) do
    if name:match('^Adan') then
      package.loaded[name] = nil
    end
  end

  -- Reload init.lua (which re-requires 'Adan')
  dofile(vim.fn.stdpath('config') .. '/init.lua')

  vim.notify('Full config reloaded!', vim.log.levels.INFO)
end, { desc = 'Reload entire config' })

-- =============================================================================
-- Create / Open a Daily Note Markdown file
-- =============================================================================
vim.keymap.set('n', '<leader>n', function()
  local dir = vim.fn.expand('~/Notes/DailyNotes')
  local filepath = dir .. '/' .. os.date('%Y-%m-%d') .. '.md'
  vim.fn.mkdir(dir, 'p')
  vim.cmd.edit(filepath)
end, { desc = "Open today's daily note" })

-- =============================================================================
-- undo tree keymap
-- =============================================================================

vim.keymap.set('n', '<leader>u', function()
  require('undotree').open()
end, { desc = 'Toggle undotree' })

-- =============================================================================
-- Mason Lazy Load
-- =============================================================================

vim.keymap.set('n', '<leader>cm', function()
  require('Adan.lsp.mason').open()
end, { desc = 'Mason' })
