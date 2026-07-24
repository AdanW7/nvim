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

vim.api.nvim_create_user_command('SanitizeText', function(opts)
  local replacements = {
    -- UTF-8 zero-width / formatting chars
    ['\226\128\139'] = '', -- U+200B ZERO WIDTH SPACE
    ['\226\128\140'] = '', -- U+200C ZERO WIDTH NON-JOINER
    ['\226\128\141'] = '', -- U+200D ZERO WIDTH JOINER
    ['\226\128\142'] = '', -- U+200E LEFT-TO-RIGHT MARK
    ['\226\128\143'] = '', -- U+200F RIGHT-TO-LEFT MARK
    ['\239\187\191'] = '', -- U+FEFF BOM / ZERO WIDTH NO-BREAK SPACE

    -- Other problematic invisible characters
    ['\194\173'] = '', -- U+00AD SOFT HYPHEN
    ['\226\129\160'] = '', -- U+2060 WORD JOINER

    -- Common spacing characters
    ['\194\160'] = ' ', -- U+00A0 NON-BREAKING SPACE
    ['\160'] = ' ', -- Raw CP1252/Latin-1 NBSP byte

    -- Raw CP1252 punctuation bytes
    ['\145'] = "'", -- Left single quote
    ['\146'] = "'", -- Right single quote
    ['\147'] = '"', -- Left double quote
    ['\148'] = '"', -- Right double quote
    ['\150'] = '-', -- En dash
    ['\151'] = '-', -- Em dash
    ['\133'] = '...', -- Ellipsis

    -- Proper UTF-8 smart punctuation
    ['‘'] = "'",
    ['’'] = "'",
    ['“'] = '"',
    ['”'] = '"',
    ['–'] = '-',
    ['—'] = '-',
    ['…'] = '...',
  }

  local start_line, end_line

  if opts.range == 0 then
    -- No explicit range provided: operate on entire buffer
    start_line = 0
    end_line = -1
  else
    -- Explicit range or visual selection
    start_line = opts.line1 - 1
    end_line = opts.line2
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

  local changed = false
  local replacement_count = 0

  for i, line in ipairs(lines) do
    local cleaned = line

    for bad, replacement in pairs(replacements) do
      local n
      cleaned, n = cleaned:gsub(bad, replacement)
      replacement_count = replacement_count + n
    end

    if cleaned ~= line then
      lines[i] = cleaned
      changed = true
    end
  end

  if changed then
    vim.api.nvim_buf_set_lines(bufnr, start_line, end_line, false, lines)

    vim.notify(
      string.format(
        'Sanitized text (%d replacement%s)',
        replacement_count,
        replacement_count == 1 and '' or 's'
      ),
      vim.log.levels.INFO
    )
  else
    vim.notify('No problematic characters found', vim.log.levels.INFO)
  end
end, {
  range = true,
  addr = 'lines',
  desc = 'Sanitize invisible Unicode characters, CP1252 bytes, smart punctuation, and non-standard whitespace',
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
