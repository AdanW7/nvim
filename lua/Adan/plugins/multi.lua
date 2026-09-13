-- local M = {}
-- function M.setup()
--   local function setup_visual_multi()
--     if package.loaded['visual-multi'] then
--       return
--     end
--
--     vim.g.VM_default_mappings = 0
--     vim.g.VM_mouse_mappings = 1
--     vim.g.VM_leader = '<leader>m'
--     vim.g.VM_custom_motions = {
--       ['gh'] = '0',
--       ['gs'] = '^',
--       ['gl'] = '$',
--     }
--     vim.g.VM_maps = {
--       ['Find Under'] = '<leader>mn',
--       ['Find Subword Under'] = '<leader>mN',
--       ['Select All'] = '<leader>mA',
--       ['Start Regex Search'] = '<leader>m/',
--       ['Add Cursor At Pos'] = '<leader>ma',
--       ['Add Cursor Down'] = '<leader>mj',
--       ['Add Cursor Up'] = '<leader>mk',
--       ['Toggle Mappings'] = '<leader>m<Space>',
--       ['Reselect Last'] = '<leader>mgS',
--       C = '',
--     }
--     vim.pack.add({
--       'https://github.com/mg979/vim-visual-multi',
--     }, { load = true, confirm = false })
--     vim.keymap.set(
--       { 'n', 'x' },
--       'C',
--       '<Plug>(VM-Add-Cursor-Down)',
--       { remap = true, desc = 'MC: Add cursor down' }
--     )
--   end
--
--   vim.api.nvim_create_autocmd('BufRead', {
--     once = true,
--     callback = setup_visual_multi,
--   })
--
--   if vim.api.nvim_buf_get_name(0) ~= '' then
--     setup_visual_multi()
--   end
-- end
-- return M

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
