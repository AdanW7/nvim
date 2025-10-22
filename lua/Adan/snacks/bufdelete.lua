local M = {}

function M.keys()
  return {
    {
      lhs = '<leader>bd',
      rhs = function()
        Snacks.bufdelete()
      end,
      desc = 'Delete Buffer',
    },
    {
      lhs = '<leader>bD',
      rhs = function()
        Snacks.bufdelete({ force = true })
      end,
      desc = 'Delete Buffer (Force)',
    },
    {
      lhs = '<leader>bo',
      rhs = function()
        Snacks.bufdelete.other()
      end,
      desc = 'Delete Other Buffers',
    },
    {
      lhs = '<leader>ba',
      rhs = function()
        Snacks.bufdelete.all()
      end,
      desc = 'Delete All Buffers',
    },
    {
      lhs = '<leader>br',
      rhs = '<cmd>checktime<CR>',
      desc = 'Reload All Buffers',
    },
  }
end

return M
