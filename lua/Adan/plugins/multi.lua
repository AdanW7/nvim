local M = {}
function M.setup()
  vim.api.nvim_create_autocmd('BufRead', {
    once = true,
    callback = function()
      vim.g.VM_default_mappings = 0
      vim.g.VM_mouse_mappings = 1
      vim.g.VM_leader = '<leader>m'
      vim.g.VM_custom_motions = {
        ['gh'] = '0',
        ['gs'] = '^',
        ['gl'] = '$',
      }
      vim.g.VM_maps = {
        ['Find Under'] = '<leader>mn',
        ['Find Subword Under'] = '<leader>mN',
        ['Select All'] = '<leader>mA',
        ['Start Regex Search'] = '<leader>m/',
        ['Add Cursor At Pos'] = '<leader>ma',
        ['Add Cursor Down'] = '<leader>mj',
        ['Add Cursor Up'] = '<leader>mk',
        ['Toggle Mappings'] = '<leader>m<Space>',
        ['Reselect Last'] = '<leader>mgS',
        C = '',
      }
      vim.pack.add({
        'https://github.com/mg979/vim-visual-multi',
      }, { load = true, confirm = false })
      vim.keymap.set(
        { 'n', 'x' },
        'C',
        '<Plug>(VM-Add-Cursor-Down)',
        { remap = true, desc = 'MC: Add cursor down' }
      )
    end,
  })
end
return M
