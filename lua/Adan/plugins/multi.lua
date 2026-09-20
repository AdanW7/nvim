local M = {}

function M.setup()
  local function add_cursor_and_move(motion)
    return function()
      vim.cmd('normal! Q')
      vim.cmd('normal! ' .. motion)
    end
  end

  local function cword_pattern(bounded)
    local cword = vim.fn.expand('<cword>')
    if cword == '' then
      return nil
    end
    local escaped = vim.fn.escape(cword, '\\/.*$^~[]')
    return bounded and ('\\<' .. escaped .. '\\>') or escaped
  end

  local function select_all(bounded)
    return function()
      local pattern = cword_pattern(bounded)
      if not pattern then
        return
      end
      vim.fn.setreg('/', pattern)
      vim.o.hlsearch = true
      vim.cmd('normal! 1Q')
    end
  end

  local maps = {
    { 'n', '<leader>Q', select_all(true), 'MC: Select all occurrences of word' },
    { 'n', '<Space><Space>', 'q=', 'MC: Toggle follow-mode' },
  }

  for _, m in ipairs(maps) do
    vim.keymap.set(m[1], m[2], m[3], { desc = m[4] })
  end

  vim.keymap.set({ 'n', 'x' }, 'C', add_cursor_and_move('j'), { desc = 'MC: Add cursor down' })
end

return M
