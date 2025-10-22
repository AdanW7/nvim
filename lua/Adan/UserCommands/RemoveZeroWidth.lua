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
