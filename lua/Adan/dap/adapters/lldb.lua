local dap = require('dap')

local function codelldb_command()
  local ok, registry = pcall(require, 'mason-registry')
  if ok then
    local ok_pkg, pkg = pcall(registry.get_package, 'codelldb')
    ---@type any
    local pkg_any = pkg
    if ok_pkg and pkg_any and pkg_any.is_installed and pkg_any.get_install_path and pkg_any:is_installed() then
      local sep = package.config:sub(1, 1)
      local exe = (sep == '\\') and 'codelldb.exe' or 'codelldb'
      return table.concat({ pkg_any:get_install_path(), 'extension', 'adapter', exe }, sep)
    end
  end
  return 'codelldb'
end

dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = codelldb_command(),
    args = { '--port', '${port}' },
  },
}
