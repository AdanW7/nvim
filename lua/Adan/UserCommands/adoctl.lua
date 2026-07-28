local M = {}

-- Azure DevOps quickfix integration.
--
-- Commands:
--   :AdoMine
--   :AdoSearch <title terms>
--   :AdoChangeRequests <title terms>
--   :AdoAnomalies <title terms>
--   :AdoFeatures <title terms>
--   :AdoOpen
--
-- Results are written to the quickfix list. Press <CR> or o on a result to
-- open the attached Azure DevOps work item URL in your browser.
--
-- Preferred install:
--   gleam export escript
--   cp ./adoctl ~/.config/nvim/bin/adoctl
--
-- This helper runs that bundled escript through `escript`, so it works on
-- macOS, Linux, and Windows as long as Erlang/OTP is installed.

local function adoctl_command()
  local bundled = vim.fs.joinpath(vim.fn.stdpath('config'), 'bin', 'adoctl')
  if vim.fn.filereadable(bundled) == 1 then
    local escript = vim.fn.exepath('escript')
    if escript == '' then
      vim.notify(
        'escript is not executable. Install Erlang/OTP and ensure escript is on PATH.',
        vim.log.levels.ERROR
      )
      return
    end
    return { escript, bundled }
  end

  local command = vim.fn.exepath('adoctl')
  if command ~= '' then
    return { command }
  end

  vim.notify(
    'adoctl was not found. Copy the escript to ' .. bundled .. ' or put adoctl on PATH.',
    vim.log.levels.ERROR
  )
end

local function adoctl(args, on_done)
  local command = adoctl_command()
  if not command then
    return
  end

  local stdout = {}
  local stderr = {}
  vim.fn.jobstart(vim.list_extend(command, args), {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      stdout = data or {}
    end,
    on_stderr = function(_, data)
      stderr = data or {}
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify(table.concat(stderr, '\n'), vim.log.levels.ERROR)
        return
      end
      on_done(table.concat(stdout, '\n'))
    end,
  })
end

local function entry_text(item)
  local assignee = item.assigned_to or 'Unassigned'
  return string.format(
    '%s [%s] %s / %s / %s - %s',
    item.id,
    item.project,
    item.type,
    item.state,
    assignee,
    item.title
  )
end

local function qf_items(items)
  return vim.tbl_map(function(item)
    return {
      text = entry_text(item),
      valid = 1,
      user_data = item,
    }
  end, items)
end

local function qf_buffer()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.bo[bufnr].filetype == 'qf' then
      return bufnr
    end
  end
end

function M.open_current()
  local qf = vim.fn.getqflist({ idx = 0, items = 0 })
  local item = qf.items[qf.idx]
  local data = item and item.user_data

  if not data or not data.url then
    vim.notify('No ADO URL is attached to the current quickfix item.', vim.log.levels.WARN)
    return
  end

  vim.ui.open(data.url)
end

local function install_qf_maps()
  local bufnr = qf_buffer()
  if not bufnr then
    return
  end

  local opts = { buffer = bufnr, silent = true, desc = 'Open Azure DevOps work item' }
  vim.keymap.set('n', '<CR>', M.open_current, opts)
  vim.keymap.set('n', 'o', M.open_current, opts)
end

local function show_quickfix(title, items)
  vim.fn.setqflist({}, ' ', {
    title = title,
    items = qf_items(items),
  })
  vim.cmd('copen')
  install_qf_maps()
end

local function decode_items(body)
  local ok, items = pcall(vim.json.decode, body)
  if not ok then
    vim.notify('adoctl returned invalid JSON.', vim.log.levels.ERROR)
    return
  end
  return items
end

function M.search(term, opts)
  opts = opts or {}
  local args = { 'search', term, '--format', 'json' }

  if opts.project then
    vim.list_extend(args, { '--project', opts.project })
  end
  if opts.type then
    vim.list_extend(args, { '--type', opts.type })
  end
  if opts.state then
    vim.list_extend(args, { '--state', opts.state })
  end
  if opts.assigned_to_me then
    table.insert(args, '--assigned-to-me')
  end

  adoctl(args, function(body)
    local items = decode_items(body)
    if items then
      show_quickfix('ADO search: ' .. term, items)
    end
  end)
end

function M.mine()
  adoctl({ 'list', '--format', 'json' }, function(body)
    local items = decode_items(body)
    if items then
      show_quickfix('My ADO work items', items)
    end
  end)
end

vim.api.nvim_create_user_command('AdoMine', function()
  M.mine()
end, { desc = 'Populate quickfix with ADO work items assigned to you' })

vim.api.nvim_create_user_command('AdoSearch', function(command)
  M.search(command.args)
end, { nargs = '+', desc = 'Search ADO work item titles into quickfix' })

vim.api.nvim_create_user_command('AdoChangeRequests', function(command)
  M.search(command.args, { type = 'Change Request' })
end, { nargs = '+', desc = 'Search ADO Change Requests into quickfix' })

vim.api.nvim_create_user_command('AdoAnomalies', function(command)
  M.search(command.args, { type = 'Anomaly' })
end, { nargs = '+', desc = 'Search ADO Anomalies into quickfix' })

vim.api.nvim_create_user_command('AdoFeatures', function(command)
  M.search(command.args, { type = 'Feature' })
end, { nargs = '+', desc = 'Search ADO Features into quickfix' })

vim.api.nvim_create_user_command('AdoOpen', function()
  M.open_current()
end, { desc = 'Open the current ADO quickfix item in a browser' })

return M
