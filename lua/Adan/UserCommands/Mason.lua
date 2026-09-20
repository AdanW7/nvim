vim.api.nvim_create_user_command('MasonRefresh', function()
  require('mason-registry').refresh()
end, {})
