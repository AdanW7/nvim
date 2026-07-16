vim.api.nvim_create_user_command('StartupProfile', function(opts)
  local runs = tonumber(opts.args) or 3
  local log_files = {}

  vim.notify(string.format('Profiling startup (%d runs)...', runs), vim.log.levels.INFO)

  -- Run multiple times and average
  for i = 1, runs do
    local log_file = vim.fn.tempname() .. '-nvim-startup-' .. i .. '.log'
    local result = vim.system({ vim.v.progpath, '--startuptime', log_file, '--headless', '+qall' }, {
      text = true,
    }):wait()
    if result.code ~= 0 then
      vim.notify(result.stderr or 'Startup profile run failed', vim.log.levels.ERROR)
      return
    end
    table.insert(log_files, log_file)
  end

  -- Parse all runs, accumulate self_time per label
  local label_data = {} -- label -> { total_self, count, last_total }
  local run_totals = {}

  for _, log_file in ipairs(log_files) do
    local lines = vim.fn.readfile(log_file)
    for _, line in ipairs(lines) do
      local t = line:match('^%s*(%d+%.%d+)%s+%d+%.%d+:%s+%-%-%- NVIM STARTED %-%-%- ?$')
      if t then
        table.insert(run_totals, tonumber(t))
      end
      local total, self_time, label = line:match('^%s*(%d+%.%d+)%s+(%d+%.%d+)%s+%d+%.%d+:%s+(.+)$')
      if total and self_time then
        if not label_data[label] then
          label_data[label] = { total_self = 0, count = 0, last_total = 0 }
        end
        label_data[label].total_self = label_data[label].total_self + tonumber(self_time)
        label_data[label].count = label_data[label].count + 1
        label_data[label].last_total = tonumber(total)
      end
    end
  end

  -- Average the totals
  local avg_total = 0
  local min_total, max_total = math.huge, 0
  for _, t in ipairs(run_totals) do
    avg_total = avg_total + t
    min_total = math.min(min_total, t)
    max_total = math.max(max_total, t)
  end
  avg_total = avg_total / math.max(#run_totals, 1)

  -- Build sorted entries using averaged self_time
  local entries = {}
  for label, data in pairs(label_data) do
    table.insert(entries, {
      label = label,
      self_time = data.total_self / data.count,
      total = data.last_total,
    })
  end
  table.sort(entries, function(a, b)
    return a.self_time > b.self_time
  end)

  -- Format output
  local out = {
    string.format(
      'Startup profile — avg: %.0fms  min: %.0fms  max: %.0fms  (%d runs)',
      avg_total,
      min_total,
      max_total,
      runs
    ),
    string.format('Log files: %s', log_files[1]:gsub('-1%.log', '-*.log')),
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
    local marker = e.self_time >= 20 and ' ◀ SLOW' or e.self_time >= 5 and ' ·' or ''
    table.insert(out, string.format('%-10.1f %-11.1f %s%s', e.self_time, e.total, label, marker))
  end

  table.insert(out, string.rep('─', 80))
  table.insert(out, string.format('Average startup time: %.0f ms', avg_total))
  table.insert(out, string.format('Run :StartupProfile N  to profile with N runs'))

  -- Open in split
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out)
  vim.bo[buf].filetype = 'startupprofile'
  vim.bo[buf].modifiable = false
  vim.cmd('botright 20split')
  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_buf_call(buf, function()
    vim.fn.matchadd('ErrorMsg', '◀ SLOW')
    vim.fn.matchadd('WarningMsg', '·')
    vim.fn.matchadd('Comment', '^Log files:.*')
  end)

  -- Don't delete logs so user can inspect them
end, {
  desc = 'Profile Neovim startup time (optional: number of runs, default 3)',
  nargs = '?',
})
