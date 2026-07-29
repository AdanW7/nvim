local M = {}

-- Azure DevOps quickfix integration.
--
-- Commands:
--   :AdoMine
--   :AdoSearch <title terms> [--project P] [--type T] [--state S] [--assigned-to N|@Me] [--created-by N|@Me]
--   :AdoChangeRequests <title terms>
--   :AdoAnomalies <title terms>
--   :AdoFeatures <title terms>
--   :AdoAssignedTo <display name>|@Me
--   :AdoCreatedBy <display name>|@Me
--   :AdoRoute
--   :AdoOpen
--   :AdoCtl <raw adoctl args...>
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

-- ---------------------------------------------------------------------------
-- Argument tokenizing
-- ---------------------------------------------------------------------------

-- Splits a raw command-line argument string into tokens, respecting single
-- and double quotes instead of being split apart by whitespace.
-- This is needed anywhere we must distinguish flags from multi-word values;
-- plain %s+ splitting (and Neovim's own command.fargs) can't do that
-- it has no concept of quoting,
local function tokenize(str)
  local tokens = {}
  local i, len = 1, #str

  while i <= len do
    while i <= len and str:sub(i, i):match('%s') do
      i = i + 1
    end
    if i > len then
      break
    end

    local quote = str:sub(i, i)
    if quote == '"' or quote == "'" then
      i = i + 1
      local buf = {}
      while i <= len and str:sub(i, i) ~= quote do
        if quote == '"' and str:sub(i, i) == '\\' and str:sub(i + 1, i + 1) == quote then
          table.insert(buf, quote)
          i = i + 2
        else
          table.insert(buf, str:sub(i, i))
          i = i + 1
        end
      end
      table.insert(tokens, table.concat(buf))
      i = i + 1 -- skip closing quote
    else
      local start = i
      while i <= len and not str:sub(i, i):match('%s') do
        i = i + 1
      end
      table.insert(tokens, str:sub(start, i - 1))
    end
  end

  return tokens
end

-- ---------------------------------------------------------------------------
-- @Me handling
-- ---------------------------------------------------------------------------

local function is_me(value)
  return value ~= nil and value:lower() == '@me'
end

-- ---------------------------------------------------------------------------
-- Completion
-- ---------------------------------------------------------------------------

local SUBCOMMANDS = { 'projects', 'list', 'search', 'cr', 'anomalies', 'features', 'url', 'open' }
local SEARCH_FLAGS = {
  '--assigned-to',
  '--assigned-to-me',
  '--created-by',
  '--created-by-me',
  '--submitted-by',
  '--project',
  '--state',
  '--type',
  '--include-closed',
  '--unassigned-filter',
  '--format',
}

-- Best-effort defaults; adjust to whatever your org's process actually uses.
-- These aren't fetched from ADO because there's no "list valid states/types
-- for this project" call wired up yet -- static lists are a reasonable
-- starting point for tab-complete, not a source of truth.
local WORK_ITEM_TYPES = { 'Change Request', 'Anomaly', 'Feature', 'Bug', 'Task', 'User Story' }
local WORK_ITEM_STATES = { 'New', 'Active', 'Resolved', 'Closed', 'Removed', 'In Review' }

local project_names_cache

-- Fetches project names once and caches them for the session. Synchronous
-- (blocking) because Neovim's `complete` callback has to return a list
-- immediately -- there's no async completion protocol here. Acceptable
-- since it only pays the cost once, on first tab-complete.
local function project_names()
  if project_names_cache then
    return project_names_cache
  end

  local command = adoctl_command()
  if not command then
    return {}
  end

  local output = vim.fn.system(vim.list_extend(command, { 'projects', '--format', 'json' }))
  if vim.v.shell_error ~= 0 then
    return {}
  end

  local ok, names = pcall(vim.json.decode, output)
  if not ok or type(names) ~= 'table' then
    return {}
  end

  project_names_cache = names
  return names
end

local function starts_with(candidate, arg_lead)
  return candidate:lower():find(arg_lead:lower(), 1, true) == 1
end

local function filter_prefix(list, arg_lead)
  return vim.tbl_filter(function(v)
    return starts_with(v, arg_lead)
  end, list)
end

-- Returns the word immediately before the one currently being typed, e.g.
-- for "AdoSearch foo --project ba|" (cursor at |) this returns "--project".
-- Note: this still splits on plain whitespace (not quote-aware), so
-- completion after a quoted multi-word value may not be perfectly accurate.
-- That only affects tab-complete suggestions, not command execution.
local function preceding_word(cmdline, cursor_pos)
  local before = cmdline:sub(1, cursor_pos)
  local words = vim.split(before, '%s+', { trimempty = true })
  return words[#words - (before:sub(-1) == ' ' and 0 or 1)]
end

local function complete_search(arg_lead, cmdline, cursor_pos)
  local prev = preceding_word(cmdline, cursor_pos)

  if prev == '--assigned-to' or prev == '--created-by' or prev == '--submitted-by' then
    return filter_prefix({ '@Me' }, arg_lead)
  elseif prev == '--project' then
    return filter_prefix(project_names(), arg_lead)
  elseif prev == '--type' then
    return filter_prefix(WORK_ITEM_TYPES, arg_lead)
  elseif prev == '--state' then
    return filter_prefix(WORK_ITEM_STATES, arg_lead)
  elseif prev == '--format' then
    return filter_prefix({ 'json' }, arg_lead)
  else
    return filter_prefix(SEARCH_FLAGS, arg_lead)
  end
end

local function complete_person(arg_lead)
  return filter_prefix({ '@Me' }, arg_lead)
end

local function complete_adoctl(arg_lead, cmdline, cursor_pos)
  local before = cmdline:sub(1, cursor_pos)
  local word_count = #vim.split(before, '%s+', { trimempty = true })

  -- First positional arg after "AdoCtl " is the subcommand.
  if word_count <= 1 or (word_count == 1 and before:sub(-1) ~= ' ') then
    return filter_prefix(SUBCOMMANDS, arg_lead)
  end

  return complete_search(arg_lead, cmdline, cursor_pos)
end

-- ---------------------------------------------------------------------------
-- Quickfix rendering
-- ---------------------------------------------------------------------------

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

-- Raw output display for AdoCtl: no JSON assumptions, just show whatever
-- the CLI printed, in a scratch split. Distinct from show_quickfix, which
-- expects structured work item JSON.
local function show_raw_output(body)
  local lines = vim.split(body, '\n', { plain = true })
  vim.cmd('botright new')
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = 'nofile'
  vim.bo[bufnr].bufhidden = 'wipe'
  vim.bo[bufnr].swapfile = false
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
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
      if is_me(parts[i + 1]) then
        opts.assigned_to_me = true
      else
        opts.assigned_to = parts[i + 1]
      end
      i = i + 2
    elseif part == '--created-by' or part == '--submitted-by' then
      if is_me(parts[i + 1]) then
        opts.created_by_me = true
      else
        opts.created_by = parts[i + 1]
      end
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

-- Builds --created-by / --created-by-me / --assigned-to / --assigned-to-me
-- flags from an opts table shared by M.search and M.list.
local function person_flags(opts)
  local args = {}
  if opts.assigned_to_me then
    table.insert(args, '--assigned-to-me')
  elseif opts.assigned_to then
    vim.list_extend(args, { '--assigned-to', opts.assigned_to })
  end
  if opts.created_by_me then
    table.insert(args, '--created-by-me')
  elseif opts.created_by then
    vim.list_extend(args, { '--created-by', opts.created_by })
  end
  return args
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
  vim.list_extend(args, person_flags(opts))

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
  vim.list_extend(args, person_flags(opts))

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

vim.api.nvim_create_user_command(
  'AdoSearch',
  function(command)
    local term, opts = parse_command_args(tokenize(command.args))
    M.search(term, opts)
  end,
  { nargs = '+', complete = complete_search, desc = 'Search ADO work item titles into quickfix' }
)

vim.api.nvim_create_user_command('AdoChangeRequests', function(command)
  local term, opts = parse_command_args(tokenize(command.args))
  opts.type = 'Change Request'
  M.search(term, opts)
end, { nargs = '+', complete = complete_search, desc = 'Search ADO Change Requests into quickfix' })

vim.api.nvim_create_user_command('AdoAnomalies', function(command)
  local term, opts = parse_command_args(tokenize(command.args))
  opts.type = 'Anomaly'
  M.search(term, opts)
end, { nargs = '+', complete = complete_search, desc = 'Search ADO Anomalies into quickfix' })

vim.api.nvim_create_user_command('AdoFeatures', function(command)
  local term, opts = parse_command_args(tokenize(command.args))
  opts.type = 'Feature'
  M.search(term, opts)
end, { nargs = '+', complete = complete_search, desc = 'Search ADO Features into quickfix' })

vim.api.nvim_create_user_command('AdoAssignedTo', function(command)
  local name = table.concat(command.fargs, ' ')
  if is_me(name) then
    M.mine()
    return
  end
  M.list({ assigned_to = name, title = 'ADO assigned to: ' .. name })
end, {
  nargs = '+',
  complete = function(arg_lead)
    return complete_person(arg_lead)
  end,
  desc = 'Populate quickfix with ADO work items assigned to a person (@Me for yourself)',
})

vim.api.nvim_create_user_command('AdoCreatedBy', function(command)
  local name = table.concat(command.fargs, ' ')
  if is_me(name) then
    M.list({ created_by_me = true, title = 'ADO created by: me' })
    return
  end
  M.list({ created_by = name, title = 'ADO created by: ' .. name })
end, {
  nargs = '+',
  complete = function(arg_lead)
    return complete_person(arg_lead)
  end,
  desc = 'Populate quickfix with ADO work items created by a person (@Me for yourself)',
})

vim.api.nvim_create_user_command('AdoOpen', function()
  M.open_current()
end, { desc = 'Open the current ADO quickfix item in a browser' })

vim.api.nvim_create_user_command('AdoRoute', function()
  M.route()
end, { desc = 'Make the current quickfix list open ADO IDs with <CR>' })

-- `list` and `search` are the two adoctl subcommands that return a JSON
-- array of work items (when passed --format json), so they're the only
-- ones AdoCtl routes into the quickfix list. Everything else (projects,
-- url, open, cr, anomalies, features, ...) still goes to the raw scratch
-- buffer via show_raw_output, since AdoCtl is meant as a generic passthrough
-- and can't assume every subcommand's output is a work-item list.
local QF_SUBCOMMANDS = { list = true, search = true }

-- Ensures --format json is present so the subcommand actually emits JSON;
-- if the user already passed --format (json or otherwise) this leaves it
-- alone rather than appending a conflicting second --format flag.
local function ensure_json_format(args)
  for _, arg in ipairs(args) do
    if arg == '--format' then
      return args
    end
  end
  local with_format = vim.list_extend({}, args)
  vim.list_extend(with_format, { '--format', 'json' })
  return with_format
end

vim.api.nvim_create_user_command('AdoCtl', function(command)
  local args = tokenize(command.args)
  local subcommand = args[1]

  if QF_SUBCOMMANDS[subcommand] then
    adoctl(ensure_json_format(args), function(body)
      local items = decode_items(body)
      if items then
        show_quickfix('AdoCtl ' .. command.args, items)
      end
    end)
  else
    adoctl(args, show_raw_output)
  end
end, {
  nargs = '*',
  complete = complete_adoctl,
  desc = 'Run adoctl with raw CLI arguments; list/search go to quickfix, everything else to a scratch buffer',
})

return M
