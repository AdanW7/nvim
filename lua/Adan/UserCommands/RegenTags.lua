vim.api.nvim_create_user_command('RegenTags', function()
  vim.system({ 'ctags', '--fields=+n+S', '--c-kinds=+p', '-R', '.' }, { text = true }, function(res)
    if res.code == 0 then
      vim.schedule(function()
        vim.notify('ctags regenerated', vim.log.levels.INFO)
      end)
    else
      vim.schedule(function()
        vim.notify('ctags failed:\n' .. (res.stderr or ''), vim.log.levels.ERROR)
      end)
    end
  end)
end, {})
