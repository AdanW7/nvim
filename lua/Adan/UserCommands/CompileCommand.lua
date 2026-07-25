---@return string
local function iar_converter_path()
  local source = debug.getinfo(1, 'S').source:sub(2)
  return vim.fn.fnamemodify(source, ':h') .. '/iar_to_clang_compdb.py'
end

---@return string?
local function python_executable()
  for _, candidate in ipairs({ 'python3', 'python', 'py' }) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end

  return nil
end

---@param message string
---@param level? integer
local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'CompileCommands' })
end

---@param message string
local function fail(message)
  notify(message, vim.log.levels.ERROR)
end

---@param bufnr integer
---@param path string
---@return boolean
local function is_json_buffer(bufnr, path)
  return vim.bo[bufnr].filetype == 'json' or path:lower():match('%.json$') ~= nil
end

---@param path string
---@return boolean
---@param command_name string
---@return string? path
---@return string? err
local function compile_commands_input(command_name)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)

  if path == '' then
    return nil, 'Current buffer does not have a file path.'
  end

  if vim.bo[bufnr].modified then
    return nil,
      'Current buffer has unsaved changes; write it before running ' .. command_name .. '.'
  end

  if not is_json_buffer(bufnr, path) then
    return nil, command_name .. ' only runs from a JSON buffer.'
  end

  if vim.fn.filereadable(path) ~= 1 then
    return nil, 'Input file not found: ' .. path
  end

  return path, nil
end

---@class CompileCommandsSplitOpts
---@field out_root? string
---@field also_write_flat_files? boolean

---@param opts? CompileCommandsSplitOpts
local function split(opts)
  opts = opts or {}

  local python = python_executable()
  if not python then
    fail('Python was not found on PATH.')
    return
  end

  local input_file, input_err = compile_commands_input('SplitCompileCommands')
  if input_err then
    fail(input_err)
    return
  end
  ---@cast input_file string

  local script = iar_converter_path()
  if vim.fn.filereadable(script) ~= 1 then
    fail('Converter script not found: ' .. script)
    return
  end

  local out_root = opts.out_root or '.clangd-db'
  local command = { python, script, '--split', input_file, '--out-root', out_root }
  if opts.also_write_flat_files then
    table.insert(command, '--flat')
  end

  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    fail(vim.trim(result.stderr or 'Python splitter failed.'))
    return
  end

  notify(vim.trim(result.stdout or 'Done.'))
end

---@param line1 integer
---@param line2 integer
local function iar_to_clang(line1, line2)
  local python = python_executable()
  if not python then
    fail('Python was not found on PATH.')
    return
  end

  local script = iar_converter_path()
  if vim.fn.filereadable(script) ~= 1 then
    fail('Converter script not found: ' .. script)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local whole_buffer = line1 == 1 and line2 == line_count
  local lines = vim.api.nvim_buf_get_lines(bufnr, line1 - 1, line2, false)
  local command = { python, script }
  if not whole_buffer then
    table.insert(command, '--fragment')
  end

  local result = vim.system(command, {
    stdin = table.concat(lines, '\n') .. '\n',
    text = true,
  }):wait()
  if result.code ~= 0 then
    fail(vim.trim(result.stderr or 'Python converter failed.'))
    return
  end

  local converted = vim.split(result.stdout or '', '\n', { plain = true })
  if converted[#converted] == '' then
    table.remove(converted)
  end

  vim.api.nvim_buf_set_lines(bufnr, line1 - 1, line2, false, converted)
  notify(
    whole_buffer and 'Converted the complete compilation database.'
      or string.format('Converted lines %d-%d.', line1, line2)
  )
end

vim.api.nvim_create_user_command('SplitCompileCommands', function(command_opts)
  split({
    out_root = command_opts.args ~= '' and command_opts.args or nil,
    also_write_flat_files = command_opts.bang,
  })
end, {
  bang = true,
  nargs = '?',
  complete = 'dir',
  desc = 'Split or copy the active compile_commands.json by detected configuration using Python',
})

vim.api.nvim_create_user_command('IarToClangComp', function(command_opts)
  iar_to_clang(command_opts.line1, command_opts.line2)
end, {
  range = '%',
  nargs = 0,
  desc = 'Convert an IAR compilation database range to clangd JSON using Python',
})
