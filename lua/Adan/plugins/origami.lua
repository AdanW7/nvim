local M = {}

local fold_util = {}

---@type Adan.FoldRanges
local fold_ranges = {}
---@type Adan.FoldRangeMap
local fold_ranges_map = {}
---@type Adan.FoldRange|nil
local current_fold = nil

---@param bufnr Adan.Bufnr
function fold_util.update_ranges(bufnr)
  local client = vim.lsp.get_clients({ bufnr = bufnr, method = 'textDocument/foldingRange' })[1]
  if not client then
    return
  end

  local params = { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
  local tick = vim.b[bufnr].changedtick

  client:request('textDocument/foldingRange', params, function(err, ranges)
    if
      err
      or not ranges
      or not vim.api.nvim_buf_is_valid(bufnr)
      or tick ~= vim.b[bufnr].changedtick
    then
      return
    end

    -- Rebuild fold ranges as a map in statuscol
    local ranges_map = {} ---@type table<integer, Adan.FoldRange>
    for i, range in ipairs(ranges) do
      ranges[i] = {
        start_line = range.startLine + 1,
        end_line = range.endLine + 1,
      }
      ranges_map[range.startLine + 1] = ranges[i]
    end

    -- Sort fold ranges for goto prev fold search
    table.sort(ranges, function(a, b)
      return a.start_line < b.start_line
    end)

    fold_ranges_map[bufnr] = ranges_map
    fold_ranges[bufnr] = ranges
  end)
end

---@param row integer
---@param bufnr Adan.Bufnr
---@return Adan.FoldRange|nil
function fold_util.update_current_fold(row, bufnr)
  local ranges = fold_ranges[bufnr]
  if not ranges then
    return nil
  end

  local best_range = nil ---@type Adan.FoldRange|nil

  for i = 1, #ranges do
    local range = ranges[i]
    if range.start_line > row then
      break
    end

    if row <= range.end_line then
      best_range = range
    end
  end

  current_fold = best_range
end

---@param bufnr Adan.Bufnr
function fold_util.clear(bufnr)
  fold_ranges[bufnr] = nil
  fold_ranges_map[bufnr] = nil
end

function fold_util.goto_previous_fold()
  local bufnr = vim.api.nvim_get_current_buf()
  local ranges = fold_ranges[bufnr]
  if not ranges or #ranges == 0 then
    return
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]

  for i = #ranges, 1, -1 do
    local start_line = ranges[i].start_line

    if start_line < row then
      return vim.api.nvim_win_set_cursor(0, { start_line, 0 })
    end
  end
end

---@return string
function fold_util.statuscol()
  local winid = vim.g.statusline_winid
  local bufnr = vim.api.nvim_win_get_buf(winid)
  local lnum = vim.v.lnum

  local fold_map = fold_ranges_map[bufnr]
  if not fold_map then
    return '%s%l   '
  end

  local this_range = fold_map[lnum]
  if not this_range then
    return '%s%l   '
  end

  local closed = (vim.fn.foldclosed(lnum) == lnum)
  local icon = closed and '' or ''

  local hl = 'LineNr'
  local cursor_fold = current_fold
  if cursor_fold and this_range.start_line == cursor_fold.start_line then
    hl = 'CursorLineNr'
  end

  return '%s%l ' .. '%#' .. hl .. '#' .. icon .. '%* '
end
function M.setup()
  vim.pack.add({
    'https://github.com/chrisgrieser/nvim-origami',
  }, { load = false, confirm = false })

  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99

  -- Keymaps registered immediately with lazy requires
  vim.keymap.set('n', 'H', 'za', { noremap = true, silent = true, desc = 'Toggle fold' })
  vim.keymap.set('n', 'zk', fold_util.goto_previous_fold, {
    noremap = true,
    silent = true,
    desc = 'Go to previous fold',
  })
  vim.keymap.set('n', 'zj', 'zj', { noremap = true, silent = true, desc = 'Go to next fold' })
  vim.keymap.set('n', '<Left>', function()
    require('origami').h()
  end)
  vim.keymap.set('n', '<Right>', function()
    require('origami').l()
  end)
  vim.keymap.set('n', '<End>', function()
    require('origami').dollar()
  end)

  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = function()
      require('origami').setup({
        useLspFoldsWithTreesitterFallback = {
          enabled = true,
          foldmethodIfNeitherIsAvailable = 'indent',
        },
        foldtext = {
          lineCount = { template = ' %d Lines' },
          diagnosticsCount = true,
          gitsignsCount = true,
        },
        foldKeymaps = {
          setup = false,
          hOnlyOpensOnFirstColumn = false,
        },
        autoFold = {
          enabled = true,
          kinds = { 'comment', 'imports' },
        },
      })
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'LspAttach' }, {
    callback = function(opts)
      fold_util.update_ranges(opts.buf)
    end,
  })

  local last_row = nil
  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = function(opts)
      local row = vim.api.nvim_win_get_cursor(0)[1]
      if row ~= last_row then
        last_row = row
        fold_util.update_current_fold(row, opts.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufUnload', 'BufWipeout' }, {
    callback = function(opts)
      fold_util.clear(opts.buf)
    end,
  })

  vim.opt.statuscolumn = '%!v:lua.StatusCol()'
  function _G.StatusCol()
    return fold_util.statuscol()
  end
end
return M
