local M = {}

local function apply_keys(keys)
  if type(keys) ~= 'table' then
    return
  end

  for _, key in ipairs(keys) do
    vim.keymap.set(key.mode or 'n', key.lhs, key.rhs, { desc = key.desc })
  end
end

function M.setup()
  local snack_parts = require('Adan.snacks').modules()

  for _, mod in ipairs(snack_parts) do
    if type(mod.pre_setup) == 'function' then
      mod.pre_setup()
    end
  end

  vim.pack.add({ 'https://github.com/folke/snacks.nvim' }, { load = true, confirm = false })

  local opts = {}
  for _, mod in ipairs(snack_parts) do
    if type(mod.extend_opts) == 'function' then
      mod.extend_opts(opts)
    end
  end

  require('snacks').setup(opts)

  for _, mod in ipairs(snack_parts) do
    if type(mod.keys) == 'function' then
      apply_keys(mod.keys())
    end
    if type(mod.post_setup) == 'function' then
      mod.post_setup()
    end
  end
end

return M
