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

vim.api.nvim_create_user_command('RemoveZeroWidth', function()
  vim.cmd([[%s/\%u200B\|\%u200C\|\%u200D\|\%u200E\|\%u200F\|\%uFEFF//ge]])
  vim.notify(
    'Invisible Unicode formatting characters removed from current buffer',
    vim.log.levels.INFO
  )
end, {
  nargs = 0,
  desc = 'Remove invisible Unicode formatting characters from current buffer',
})

vim.api.nvim_create_user_command('IndentStyle', function(opts)
  local width = tonumber(opts.args)

  if not width or width < 1 then
    vim.notify('Usage: :IndentStyle <width>', vim.log.levels.ERROR)
    return
  end

  -- Set for current buffer only
  vim.bo.tabstop = width
  vim.bo.shiftwidth = width
  vim.bo.softtabstop = width

  vim.notify('Indent width set to ' .. width .. ' for current buffer', vim.log.levels.INFO)
end, {
  nargs = 1,
  desc = 'Set indent width for current buffer',
})

vim.api.nvim_create_user_command('StripWhitespace', function()
  local view = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(view)
  vim.notify('Trailing whitespace removed', vim.log.levels.INFO)
end, {
  nargs = 0,
  desc = 'Remove trailing whitespace from current buffer',
})

vim.api.nvim_create_user_command('YankPath', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  vim.notify('Yanked: ' .. path, vim.log.levels.INFO)
end, {
  nargs = 0,
  desc = 'Copy absolute path of current file to clipboard',
})
