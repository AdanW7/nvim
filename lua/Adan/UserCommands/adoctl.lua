local M = {}

-- Azure DevOps quickfix integration.
--
-- Commands:
--   :AdoMine
--   :AdoSearch <title terms>
--   :AdoChangeRequests <title terms>
--   :AdoAnomalies <title terms>
--   :AdoFeatures <title terms>
--   :AdoAssignedTo <display name>
--   :AdoCreatedBy <display name>
--   :AdoRoute
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

local ADO_QF_CONTEXT = 'adoctl'

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

local function extract_id(text)
  if not text then
    return
  end
  return text:match('^%s*(%d+)')
    or text:match('[Aa][Dd][Oo]%D+(%d+)')
    or text:match('[Ww]ork%s+[Ii]tem%D+(%d+)')
end

local function extract_project(text)
  if not text then
    return
  end
  return text:match('^%s*%d+%s+%[(.-)%]')
end

local function ado_url(id, project)
  local org = vim.env.ADO_ORG
  project = project or vim.env.ADO_PROJECT

  if not org or org == '' or not project or project == '' then
    return
  end

  return string.format(
    'https://dev.azure.com/%s/%s/_workitems/edit/%s',
    org,
    project:gsub(' ', '%%20'),
    id
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

local function current_qf_context()
  local info = vim.fn.getqflist({ context = 0 })
  return type(info.context) == 'table' and info.context.adoctl
end

local function is_ado_qf()
  return current_qf_context() == ADO_QF_CONTEXT
end

local function qf_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.bo[bufnr].filetype == 'qf' then
      return win, bufnr
    end
  end
end

local function qf_cursor_index()
  local win = qf_window()
  if win then
    return vim.api.nvim_win_get_cursor(win)[1]
  end
  return vim.fn.getqflist({ idx = 0 }).idx
end

local function open_quickfix_item(idx)
  if idx and idx > 0 then
    vim.cmd('cc ' .. idx)
  else
    vim.cmd('cc')
  end
end

function M.open_current()
  local idx = qf_cursor_index()
  local qf = vim.fn.getqflist({ items = 0 })
  local item = qf.items[idx]
  local data = item and item.user_data

  if not is_ado_qf() then
    open_quickfix_item(idx)
    return
  end

  if data and data.url then
    vim.ui.open(data.url)
    return
  end

  local id = extract_id(item and item.text)
  local url = id and ado_url(id)
  if url then
    vim.ui.open(url)
    return
  end

  open_quickfix_item(idx)
end

local function install_qf_maps()
  local _, bufnr = qf_window()
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
    context = { adoctl = ADO_QF_CONTEXT },
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

local function parse_command_args(parts)
  local term = {}
  local opts = {}
  local i = 1

  while i <= #parts do
    local part = parts[i]
    if part == '--assigned-to' then
      opts.assigned_to = parts[i + 1]
      i = i + 2
    elseif part == '--created-by' or part == '--submitted-by' then
      opts.created_by = parts[i + 1]
      i = i + 2
    elseif part == '--project' then
      opts.project = parts[i + 1]
      i = i + 2
    elseif part == '--state' then
      opts.state = parts[i + 1]
      i = i + 2
    elseif part == '--mine' then
      opts.assigned_to_me = true
      i = i + 1
    else
      table.insert(term, part)
      i = i + 1
    end
  end

  return table.concat(term, ' '), opts
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
  if opts.assigned_to then
    vim.list_extend(args, { '--assigned-to', opts.assigned_to })
  end
  if opts.created_by then
    vim.list_extend(args, { '--created-by', opts.created_by })
  end

  adoctl(args, function(body)
    local items = decode_items(body)
    if items then
      show_quickfix('ADO search: ' .. term, items)
    end
  end)
end

function M.route()
  local current = vim.fn.getqflist({ items = 0, title = 0 })
  local routed = vim.tbl_map(function(item)
    local copy = vim.tbl_extend('force', {}, item)
    local id = extract_id(copy.text)
    local project = extract_project(copy.text)
    local data = copy.user_data or {}
    if id and not data.url then
      data.id = tonumber(id)
      data.project = project or data.project
      data.url = ado_url(id, project)
      copy.user_data = data
    end
    return copy
  end, current.items)

  vim.fn.setqflist({}, 'r', {
    title = 'ADO routed: ' .. (current.title or 'quickfix'),
    context = { adoctl = ADO_QF_CONTEXT },
    items = routed,
  })
  vim.cmd('copen')
  install_qf_maps()
end

function M.mine()
  adoctl({ 'list', '--format', 'json' }, function(body)
    local items = decode_items(body)
    if items then
      show_quickfix('My ADO work items', items)
    end
  end)
end

function M.list(opts)
  opts = opts or {}
  local args = { 'list', '--format', 'json' }

  if opts.project then
    vim.list_extend(args, { '--project', opts.project })
  end
  if opts.type then
    vim.list_extend(args, { '--type', opts.type })
  end
  if opts.state then
    vim.list_extend(args, { '--state', opts.state })
  end
  if opts.assigned_to then
    vim.list_extend(args, { '--assigned-to', opts.assigned_to })
  end
  if opts.created_by then
    vim.list_extend(args, { '--created-by', opts.created_by })
  end

  adoctl(args, function(body)
    local items = decode_items(body)
    if items then
      show_quickfix(opts.title or 'ADO work items', items)
    end
  end)
end

vim.api.nvim_create_user_command('AdoMine', function()
  M.mine()
end, { desc = 'Populate quickfix with ADO work items assigned to you' })

vim.api.nvim_create_user_command('AdoSearch', function(command)
  local term, opts = parse_command_args(command.fargs)
  M.search(term, opts)
end, { nargs = '+', desc = 'Search ADO work item titles into quickfix' })

vim.api.nvim_create_user_command('AdoChangeRequests', function(command)
  local term, opts = parse_command_args(command.fargs)
  opts.type = 'Change Request'
  M.search(term, opts)
end, { nargs = '+', desc = 'Search ADO Change Requests into quickfix' })

vim.api.nvim_create_user_command('AdoAnomalies', function(command)
  local term, opts = parse_command_args(command.fargs)
  opts.type = 'Anomaly'
  M.search(term, opts)
end, { nargs = '+', desc = 'Search ADO Anomalies into quickfix' })

vim.api.nvim_create_user_command('AdoFeatures', function(command)
  local term, opts = parse_command_args(command.fargs)
  opts.type = 'Feature'
  M.search(term, opts)
end, { nargs = '+', desc = 'Search ADO Features into quickfix' })

vim.api.nvim_create_user_command('AdoAssignedTo', function(command)
  local name = table.concat(command.fargs, ' ')
  M.list({ assigned_to = name, title = 'ADO assigned to: ' .. name })
end, { nargs = '+', desc = 'Populate quickfix with ADO work items assigned to a person' })

vim.api.nvim_create_user_command('AdoCreatedBy', function(command)
  local name = table.concat(command.fargs, ' ')
  M.list({ created_by = name, title = 'ADO created by: ' .. name })
end, { nargs = '+', desc = 'Populate quickfix with ADO work items created by a person' })

vim.api.nvim_create_user_command('AdoOpen', function()
  M.open_current()
end, { desc = 'Open the current ADO quickfix item in a browser' })

vim.api.nvim_create_user_command('AdoRoute', function()
  M.route()
end, { desc = 'Make the current quickfix list open ADO IDs with <CR>' })

return M
