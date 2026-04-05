local M = {}
local zen_diag_state = nil

function M.extend_opts(opts)
  opts.zen = {
    toggles = {
      dim = false,
      git_signs = true,
      mini_diff_signs = true,
      diagnostics = true,
      inlay_hints = false,
    },
    center = true,
    show = {
      statusline = false,
      tabline = false,
    },
    win = {
      style = 'zen',
      width = 120,
      backdrop = { transparent = false, blend = 95 },
    },
    on_open = function()
      local cfg = vim.diagnostic.config()
      zen_diag_state = {
        virtual_text = cfg.virtual_text,
        virtual_lines = cfg.virtual_lines,
      }
      vim.diagnostic.config({
        virtual_text = false,
        virtual_lines = false,
      })
    end,
    on_close = function()
      if not zen_diag_state then
        return
      end
      vim.diagnostic.config({
        virtual_text = zen_diag_state.virtual_text,
        virtual_lines = zen_diag_state.virtual_lines,
      })
      zen_diag_state = nil
    end,
    zoom = {
      toggles = {
        dim = false,
      },
      center = false,
      show = {
        statusline = true,
        tabline = true,
      },
      win = {
        backdrop = false,
        width = 0,
      },
    },
  }
end

function M.keys()
  return {
    {
      lhs = '<leader>z',
      rhs = function()
        Snacks.zen()
      end,
      desc = 'Toggle Zen',
    },
    {
      lhs = '<leader>Z',
      rhs = function()
        Snacks.zen.zoom()
      end,
      desc = 'Toggle Zoom',
    },
  }
end

return M
