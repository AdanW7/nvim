vim.api.nvim_create_user_command('StartupProfile', function()
  local log_file = vim.fn.tempname() .. '-nvim-startup.log'

  -- Cross-platform: redirect stderr to nul on Windows, /dev/null on Unix
  local null_device = vim.fn.has('win32') == 1 and 'nul' or '/dev/null'
  local cmd = string.format(
    'nvim --startuptime %s --headless +qall 2>%s',
    vim.fn.shellescape(log_file),
    null_device
  )

  vim.notify('Profiling startup... please wait', vim.log.levels.INFO)
  vim.fn.system(cmd)

  local lines = vim.fn.readfile(log_file)
  if #lines == 0 then
    vim.notify('No startup log generated', vim.log.levels.ERROR)
    return
  end

  local entries = {}
  for _, line in ipairs(lines) do
    local total, self_time, label = line:match('^%s*(%d+%.%d+)%s+(%d+%.%d+)%s+%d+%.%d+:%s+(.+)$')
    if total and self_time then
      table.insert(entries, {
        total = tonumber(total),
        self_time = tonumber(self_time),
        label = label,
      })
    end
  end

  table.sort(entries, function(a, b)
    return a.self_time > b.self_time
  end)

  -- Find true total from "--- NVIM STARTED ---" line first
  local final_total = 0
  for _, line in ipairs(lines) do
    local t = line:match('^%s*(%d+%.%d+)%s+%d+%.%d+:%s+%-%-%- NVIM STARTED %-%-%- ?$')
    if t then
      final_total = tonumber(t)
      break
    end
  end
  if final_total == 0 and #entries > 0 then
    final_total = entries[1].total
  end

  local out = {
    string.format('Startup profile — total: %.0fms  (log: %s)', final_total, log_file),
    string.rep('─', 80),
    string.format('%-10s %-11s %s', 'self (ms)', 'total (ms)', 'source'),
    string.rep('─', 80),
  }

  local shown = math.min(30, #entries)
  for i = 1, shown do
    local e = entries[i]
    local label = e.label
    if #label > 55 then
      label = '…' .. label:sub(-54)
    end
    local marker = e.self_time >= 20 and ' ◀' or e.self_time >= 5 and ' ·' or ''
    table.insert(out, string.format('%-10.1f %-11.1f %s%s', e.self_time, e.total, label, marker))
  end

  table.insert(out, string.rep('─', 80))
  table.insert(out, string.format('Total startup time: %.0f ms', final_total))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].filetype = 'startupprofile'
  vim.bo[buf].modifiable = false

  vim.cmd('botright 20split')
  vim.api.nvim_win_set_buf(0, buf)

  vim.api.nvim_buf_call(buf, function()
    vim.fn.matchadd('ErrorMsg', '◀')
    vim.fn.matchadd('WarningMsg', '·')
  end)

  vim.fn.delete(log_file)
end, { desc = 'Profile Neovim startup time' })
