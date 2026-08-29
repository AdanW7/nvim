local M = {}

local function swap_params(direction)
  local ai = require('mini.ai')
  local cur = ai.find_textobject('i', 'a', { search_method = 'cover_or_next' })
  if not cur then
    return
  end

  local ref_region = direction == 'next' and { from = cur.to, to = cur.to }
    or { from = cur.from, to = cur.from }

  local neighbor = ai.find_textobject('i', 'a', {
    search_method = direction == 'next' and 'next' or 'prev',
    reference_region = ref_region,
  })
  if not neighbor then
    vim.notify('No ' .. direction .. ' parameter to swap with', vim.log.levels.WARN)
    return
  end

  local first, second = cur, neighbor
  if
    (neighbor.from.line < cur.from.line)
    or (neighbor.from.line == cur.from.line and neighbor.from.col < cur.from.col)
  then
    first, second = neighbor, cur
  end

  local function get_text(r)
    return vim.api.nvim_buf_get_text(
      0,
      r.from.line - 1,
      r.from.col - 1,
      r.to.line - 1,
      r.to.col,
      {}
    )
  end
  local function set_text(r, lines)
    vim.api.nvim_buf_set_text(0, r.from.line - 1, r.from.col - 1, r.to.line - 1, r.to.col, lines)
  end

  local first_text, second_text = get_text(first), get_text(second)
  set_text(second, first_text)
  set_text(first, second_text)

  local target = direction == 'next' and second or first
  vim.api.nvim_win_set_cursor(0, { target.from.line, target.from.col - 1 })
end

function M.setup()
  vim.pack.add({
    { src = 'https://github.com/echasnovski/mini.nvim', version = 'stable' },
  }, { load = true, confirm = false })
  require('mini.icons').setup()
  require('mini.icons').mock_nvim_web_devicons()
  require('mini.pairs').setup()
  require('mini.surround').setup({ respect_selection_type = true })
  require('mini.cursorword').setup({ delay = 100 })
  require('mini.jump').setup({
    mappings = { repeat_jump = '' },
    delay = { idle_stop = 1 },
  })
  local spec_ts = require('mini.ai').gen_spec.treesitter
  require('mini.ai').setup({
    n_lines = 1000000,
    mappings = {
      around = 'a',
      inside = 'i',
      around_next = 'aN',
      inside_next = 'iN',
      around_last = 'aL',
      inside_last = 'iL',
      goto_left = 'g[',
      goto_right = 'g]',
    },
    custom_textobjects = {
      f = spec_ts({ a = '@function.outer', i = '@function.inner' }),
      c = spec_ts({ a = '@class.outer', i = '@class.inner' }),
      i = spec_ts({ a = '@conditional.outer', i = '@conditional.inner' }),
      l = spec_ts({ a = '@loop.outer', i = '@loop.inner' }),
      a = spec_ts({ a = '@parameter.outer', i = '@parameter.inner' }),
      ['/'] = spec_ts({ a = '@comment.outer', i = '@comment.inner' }),
      B = spec_ts({ a = '@block.outer', i = '@block.inner' }),
      C = spec_ts({ a = '@call.outer', i = '@call.inner' }),
      T = spec_ts({ a = '@type.outer', i = '@type.inner' }),
    },
  })
  require('mini.statusline').setup {}
  require('mini.align').setup {}
  require('mini.sessions').setup({
    autoread = false,
    autowrite = false,
    directory = vim.fn.stdpath('data') .. '/sessions',
    force = { read = false, write = true, delete = false },
    verbose = { read = false, write = true, delete = true },
  })
  vim.keymap.set('n', '<leader>sw', function()
    vim.ui.input({ prompt = 'Session name: ' }, function(name)
      if name and name ~= '' then
        MiniSessions.write(name)
      end
    end)
  end, { desc = 'Session: write named' })
  vim.keymap.set('n', '<leader>sl', function()
    MiniSessions.select('read')
  end, { desc = 'Session: select & open' })
  vim.keymap.set('n', '<leader>sd', function()
    MiniSessions.select('delete')
  end, { desc = 'Session: select & delete' })
  local function jump(side, ai, id, lhs, desc)
    vim.keymap.set({ 'n', 'x', 'o' }, lhs, function()
      MiniAi.move_cursor(side, ai, id, {
        search_method = side == 'left' and 'prev' or 'next',
        n_lines = 1000000,
      })
    end, { desc = desc })
  end
  jump('right', 'a', 'f', ']f', 'Next function')
  jump('left', 'a', 'f', '[f', 'Prev function')
  jump('right', 'a', 'c', ']c', 'Next class')
  jump('left', 'a', 'c', '[c', 'Prev class')
  jump('right', 'a', 'i', ']i', 'Next conditional')
  jump('left', 'a', 'i', '[i', 'Prev conditional')
  jump('right', 'a', 'l', ']l', 'Next loop')
  jump('left', 'a', 'l', '[l', 'Prev loop')
  jump('right', 'a', 'a', ']a', 'Next parameter')
  jump('left', 'a', 'a', '[a', 'Prev parameter')
  jump('right', 'a', '/', ']/', 'Next comment')
  jump('left', 'a', '/', '[/', 'Prev comment')

  vim.keymap.set('n', '<leader>a', function()
    swap_params('next')
  end, { desc = 'Swap parameter with next' })
  vim.keymap.set('n', '<leader>A', function()
    swap_params('prev')
  end, { desc = 'Swap parameter with prev' })

  vim.keymap.set('n', 's', '<Nop>', { noremap = true }) -- unmap s so surround doesn't have issues, I also nver use it anyway
end
return M
