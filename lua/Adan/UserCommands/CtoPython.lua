---Thin Nvim wrapper around c_to_python.py.
---All conversion logic lives in the Python script
---This module grabs buffer lines, hands them to the script on
---stdin, and write the result back.
---@class CToPython
local M = {}

---Resolve the path to c_to_python.py, which must live alongside this file.
---@return string
local function script_path()
  local source = debug.getinfo(1, 'S').source:sub(2)
  local dir = vim.fn.fnamemodify(source, ':h')
  return dir .. '/c_to_python.py'
end

---Find a usable python interpreter on PATH.
---Tries python3/python first (Linux, macOS, and most Windows installs that
---add python.exe to PATH), then falls back to Windows's `py` launcher.
---@return string? executable name, or nil if none was found
local function python_executable()
  for _, candidate in ipairs({ 'python3', 'python', 'py' }) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end

  return nil
end

---Run c_to_python.py over `lines` and return the converted lines.
---@param lines string[] lines of C source to convert
---@return string[]? converted lines, or nil on failure
---@return string? err error message; only set when the first return is nil
function M.convert_lines(lines)
  local python = python_executable()

  if not python then
    return nil, 'no python3/python executable found on PATH'
  end

  local path = script_path()

  if vim.fn.filereadable(path) == 0 then
    return nil, 'c_to_python.py not found next to c_define_to_python.lua (' .. path .. ')'
  end

  local input = table.concat(lines, '\n')
  ---@type vim.SystemCompleted
  local result = vim.system({ python, path }, { stdin = input, text = true }):wait()

  if result.code ~= 0 then
    local message = result.stderr
    if message == nil or message == '' then
      message = 'python exited with code ' .. result.code
    end
    return nil, message
  end

  local out = vim.split(result.stdout or '', '\n', { trimempty = false })

  -- The script always writes a trailing newline; drop the resulting empty
  -- last element so buffer line counts line up with the input.
  if out[#out] == '' then
    table.remove(out)
  end

  return out
end

---Register the :CToPython user command. Converts the given range (an
---explicit range, or the whole buffer if none was given) from C
---enum/struct/#define syntax to Python, in place.
function M.setup()
  vim.api.nvim_create_user_command('CToPython', function(opts)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local converted, err = M.convert_lines(lines)

    if not converted then
      vim.notify('CToPython: ' .. err, vim.log.levels.ERROR)
      return
    end

    vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, converted)
  end, {
    range = '%',
    desc = 'Convert C enum/struct/#define lines in range to Python',
  })
end

return M
