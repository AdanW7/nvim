local uv = vim.uv or vim.loop

---@param path string
---@return string
local function dirname(path)
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(path)
  end

  return vim.fn.fnamemodify(path, ':h')
end

---@param ... string
---@return string
local function joinpath(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end

  return table.concat({ ... }, package.config:sub(1, 1))
end

local extract_configs_filter = [[
  def entry_cfg:
    (
      (.output // "" | capture("CMakeFiles[/\\\\][^/\\\\]+\\.dir[/\\\\](?<cfg>[^/\\\\]+)")?.cfg)
      //
      (.command // "" | capture("CMAKE_INTDIR=\\\\?\\\"(?<cfg>[^\\\"]+)\\\\?\\\"")?.cfg)
    );

  [ .[] | entry_cfg | select(. != null and . != "") ]
  | unique
  | .[]
]]

local split_config_filter = [[
  def entry_cfg:
    (
      (.output // "" | capture("CMakeFiles[/\\\\][^/\\\\]+\\.dir[/\\\\](?<cfg>[^/\\\\]+)")?.cfg)
      //
      (.command // "" | capture("CMAKE_INTDIR=\\\\?\\\"(?<cfg>[^\\\"]+)\\\\?\\\"")?.cfg)
    );

  map(select(entry_cfg == $cfg))
  | reverse
  | unique_by(.file)
  | reverse
]]

local copy_database_filter = '.'

local iar_to_clang_filter = [=[
  def quote_arg:
    tostring as $arg
    | if ($arg | test("[[:space:]\\\"]")) then
        "\"" + ($arg | gsub("\\\\"; "\\\\\\\\") | gsub("\""; "\\\"")) + "\""
      else
        $arg
      end;

  def clang_driver:
    if (.file // "" | test("\\.(cc|cp|cxx|cpp|c\\+\\+)$"; "i")) then
      "arm-none-eabi-g++"
    else
      "arm-none-eabi-gcc"
    end;

  def clang_arg($args; $i):
    ($args[$i] | tostring) as $arg
    | if $arg == "--cpu=Cortex-M0+" then ["-mcpu=cortex-m0plus"]
      elif $arg == "--cpu=Cortex-M4" then ["-mcpu=cortex-m4"]
      elif $arg == "--cpu_mode=thumb" then ["-mthumb"]
      elif $arg == "--fpu=VFPv4_sp" then ["-mfpu=fpv4-sp-d16"]
      elif $arg == "--char_is_unsigned" then ["-funsigned-char"]
      elif $arg == "--no_rtti" then ["-fno-rtti"]
      elif $arg == "--no_exceptions" then ["-fno-exceptions"]
      elif ($arg | startswith("--preinclude=")) then ["-include", ($arg | sub("^--preinclude="; ""))]
      elif ($arg | startswith("--diag_suppress=")) then []
      elif ([
          "--silent",
          "--debug",
          "--endian=little",
          "--no_path_in_file_macros",
          "--warnings_are_errors",
          "--fpu=None",
          "-e",
          "-Oh",
          "-On",
          "--use_c++_inline",
          "--no_cse",
          "--no_unroll",
          "--no_inline",
          "--no_code_motion",
          "--no_static_destruction",
          "--no_tbaa",
          "--no_clustering",
          "--no_scheduling"
        ] | index($arg)) then []
      else [$arg]
      end;

  def clang_args:
    . as $entry
    | ($entry.arguments // []) as $args
    | reduce range(1; ($args | length)) as $i (
        {out: [($entry | clang_driver), "--target=arm-none-eabi"], skip: false};
        if .skip then
          .skip = false
        else
          ($args[$i] | tostring) as $arg
          | if $arg == "--dlib_config" or $arg == "--diag_suppress" or $arg == "--mfc" then
              .skip = true
            elif $arg == "--preinclude" then
              .out += ["-include", ($args[$i + 1] // "" | tostring)] | .skip = true
            else
              .out += clang_arg($args; $i)
            end
        end
      )
    | .out;

  [
    .[]
    | select((.arguments? | type) == "array")
    | select((.file? // "") != "")
    | select((.type? // "COMPILER") != "LINKER")
    | {
        directory: (.directory // ""),
        command: (clang_args | map(quote_arg) | join(" ")),
        file: .file
      }
      + if (.output? // "") != "" then { output: .output } else {} end
  ]
]=]

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
local function ensure_directory(path)
  local ok = vim.fn.mkdir(path, 'p')
  return ok == 1 or vim.fn.isdirectory(path) == 1
end

---@param args string[]
---@param input_file string
---@return string? output
---@return string? err
local function run_jq(args, input_file)
  local command = { 'jq' }

  vim.list_extend(command, args)
  table.insert(command, input_file)

  if vim.system then
    local result = vim.system(command, { text = true }):wait()
    if result.code ~= 0 then
      return nil, vim.trim(result.stderr or 'jq failed')
    end

    return result.stdout or '', nil
  end

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    return nil, vim.trim(output or 'jq failed')
  end

  return output or '', nil
end

---@param path string
---@param contents string
---@return boolean ok
---@return any err
local function write_file(path, contents)
  local fd = assert(uv.fs_open(path, 'w', 438))
  local ok, err = pcall(uv.fs_write, fd, contents)
  uv.fs_close(fd)

  if not ok then
    return false, err
  end

  return true, nil
end

---@param path string
---@return integer? count
---@return string? err
local function count_entries(path)
  local output, err = run_jq({ 'length' }, path)
  if err then
    return nil, err
  end

  ---@cast output string
  return tonumber(vim.trim(output)), nil
end

---@param contents string
local function replace_current_buffer(contents)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.split(contents, '\n', { plain = true })

  if lines[#lines] == '' then
    table.remove(lines)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modified = false
end

---@param path string
---@return string? config
---@return string? err
local function first_config_name(path)
  local output, err = run_jq({ '-r', extract_configs_filter }, path)
  if err then
    return nil, err
  end

  ---@cast output string
  local configs = vim.split(vim.trim(output), '\n', { trimempty = true })
  table.sort(configs)

  if #configs == 1 then
    return configs[1], nil
  end

  return nil, nil
end

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

  if vim.fn.executable('jq') ~= 1 then
    fail('jq was not found on PATH.')
    return
  end

  local input_file, input_err = compile_commands_input('SplitCompileCommands')
  if input_err then
    fail(input_err)
    return
  end
  ---@cast input_file string

  local out_root = opts.out_root or '.clangd-db'
  local also_write_flat_files = opts.also_write_flat_files or false
  local input_dir = dirname(input_file)

  local configs_output, configs_err = run_jq({ '-r', extract_configs_filter }, input_file)
  if configs_err then
    fail('jq failed while extracting configuration names: ' .. configs_err)
    return
  end

  ---@cast configs_output string
  local configs = vim.split(vim.trim(configs_output), '\n', { trimempty = true })
  table.sort(configs)

  if not ensure_directory(out_root) then
    fail('Could not create output directory: ' .. out_root)
    return
  end

  if #configs == 0 then
    local out_file = joinpath(out_root, 'compile_commands.json')
    local output, err = run_jq({ copy_database_filter }, input_file)
    if err then
      fail('jq failed while copying compile database: ' .. err)
      return
    end

    ---@cast output string
    local ok, write_err = write_file(out_file, output)
    if not ok then
      fail('Could not write ' .. out_file .. ': ' .. tostring(write_err))
      return
    end

    local count, count_err = count_entries(out_file)
    if count_err then
      fail('jq failed while counting entries: ' .. count_err)
      return
    end

    notify('No config metadata found; copied active compile database as a single-config database.')
    notify(string.format('Wrote %4d entries -> %s', count or 0, out_file))
    notify('Done.')
    return
  end

  notify('Discovered configs: ' .. table.concat(configs, ', '))

  for _, cfg in ipairs(configs) do
    local cfg_dir = joinpath(out_root, cfg)
    if not ensure_directory(cfg_dir) then
      fail('Could not create output directory: ' .. cfg_dir)
      return
    end

    local cfg_out = joinpath(cfg_dir, 'compile_commands.json')
    local jq_args

    if #configs == 1 then
      jq_args = { copy_database_filter }
    else
      jq_args = { '--arg', 'cfg', cfg, split_config_filter }
    end

    local cfg_json, cfg_err = run_jq(jq_args, input_file)
    if cfg_err then
      fail('jq failed while generating DB for config ' .. cfg .. ': ' .. cfg_err)
      return
    end

    ---@cast cfg_json string
    local ok, write_err = write_file(cfg_out, cfg_json)
    if not ok then
      fail('Could not write ' .. cfg_out .. ': ' .. tostring(write_err))
      return
    end

    local count, count_err = count_entries(cfg_out)
    if count_err then
      fail('jq failed while counting entries for config ' .. cfg .. ': ' .. count_err)
      return
    end

    notify(string.format('Wrote %4d entries -> %s', count or 0, cfg_out))

    if also_write_flat_files then
      local flat_out = joinpath(input_dir, string.format('compile_commands.%s.json', cfg))
      local flat_ok, flat_write_err = write_file(flat_out, cfg_json)
      if not flat_ok then
        fail('Could not write ' .. flat_out .. ': ' .. tostring(flat_write_err))
        return
      end

      notify('                 -> ' .. flat_out)
    end
  end

  notify('Done.')
end

local function iar_to_clang()
  if vim.fn.executable('jq') ~= 1 then
    fail('jq was not found on PATH.')
    return
  end

  local input_file, input_err = compile_commands_input('IarToClangComp')
  if input_err then
    fail(input_err)
    return
  end
  ---@cast input_file string

  local cfg, cfg_err = first_config_name(input_file)
  if cfg_err then
    fail('jq failed while checking configuration names: ' .. cfg_err)
    return
  end

  local output, err = run_jq({ iar_to_clang_filter }, input_file)
  if err then
    fail('jq failed while converting IAR compile database: ' .. err)
    return
  end

  ---@cast output string
  local ok, write_err = write_file(input_file, output)
  if not ok then
    fail('Could not write ' .. input_file .. ': ' .. tostring(write_err))
    return
  end

  replace_current_buffer(output)

  local count, count_err = count_entries(input_file)
  if count_err then
    fail('jq failed while counting entries: ' .. count_err)
    return
  end

  if cfg then
    notify('Detected config: ' .. cfg)
  else
    notify('No config metadata found; wrote single normalized IAR compile database.')
  end

  notify(string.format('Updated %4d entries in place -> %s', count or 0, input_file))
  notify('Done.')
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
  desc = 'Split or copy the active compile_commands.json buffer by detected configuration using jq',
})

vim.api.nvim_create_user_command('IarToClangComp', function()
  iar_to_clang()
end, {
  nargs = 0,
  desc = 'Convert the active IAR JSON compilation database in place to clangd compile_commands.json using jq',
})
