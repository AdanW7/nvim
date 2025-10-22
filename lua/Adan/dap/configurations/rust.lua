local dap = require('dap')

local function find_rust_executable()
  if vim.fn.filereadable('Cargo.toml') == 1 then
    print('Building with: cargo build')
    vim.fn.system('cargo build')
  end

  local output_dir = vim.fn.getcwd() .. '/target/debug/'
  local executables = {}
  for _, file in ipairs(vim.fn.glob(output_dir .. '*', false, true)) do
    if
      vim.fn.executable(file) == 1
      and not file:match('%.d$')
      and not file:match('%.rlib$')
      and not file:match('%.so$')
      and not file:match('%.dll$')
      and not file:match('%.dylib$')
    then
      table.insert(executables, file)
    end
  end

  if #executables == 0 then
    return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  elseif #executables == 1 then
    return executables[1]
  else
    local selected = nil
    vim.ui.select(executables, {
      prompt = 'Select executable:',
      format_item = function(item)
        return vim.fn.fnamemodify(item, ':t')
      end,
    }, function(choice)
      selected = choice
    end)
    return selected
  end
end

dap.configurations.rust = {
  {
    name = 'Launch (cargo build)',
    type = 'codelldb',
    request = 'launch',
    program = find_rust_executable,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = function()
      local args_string = vim.fn.input('Arguments: ')
      return vim.split(args_string, ' +')
    end,
    runInTerminal = false,
  },
  {
    name = 'Launch (custom executable)',
    type = 'codelldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = function()
      local args_string = vim.fn.input('Arguments: ')
      return vim.split(args_string, ' +')
    end,
  },
  {
    name = 'Attach to process',
    type = 'codelldb',
    request = 'attach',
    pid = require('dap.utils').pick_process,
    args = {},
  },
}
