local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/neovim/nvim-lspconfig',
    'https://github.com/mason-org/mason.nvim',
    'https://github.com/mason-org/mason-lspconfig.nvim',
  }, { load = true, confirm = false })

  local mason_opts = {
    ensure_installed = {
      'stylua',
      'shfmt',
    },
  }

  require('mason').setup(mason_opts)
  local mr = require('mason-registry')
  mr:on('package:install:success', function()
    vim.defer_fn(function()
      vim.api.nvim_exec_autocmds('FileType', {
        buffer = vim.api.nvim_get_current_buf(),
      })
    end, 100)
  end)

  mr.refresh(function()
    for _, tool in ipairs(mason_opts.ensure_installed) do
      local p = mr.get_package(tool)
      if not p:is_installed() then
        p:install()
      end
    end
  end)

  local ok_overrides, overrides = pcall(require, 'Adan.overrides.lsp')

  local default_servers = {
    bashls = true,
    clangd = true,
    -- cmake = true,
    gleam = true,
    gopls = true,
    jade_toml = false,
    harper_ls = false,
    lua_ls = true,
    marksman = true,
    markdown_oxide = true,
    nixd = true,
    ocamllsp = false,
    powershell_es = true,
    pyrefly = false,
    ruff = true,
    rust_analyzer = true,
    texlab = true,
    tombi = true,
    ts_ls = true,
    ty = true,
    yamlls = true,
    zls = true,
    ols = true,
    lemminx = true,
  }
  local servers = vim.deepcopy(default_servers)

  if ok_overrides and type(overrides) == 'table' then
    for name, cfg in pairs(overrides) do
      if cfg ~= nil then
        servers[name] = cfg
      end
    end
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_blink, blink = pcall(require, 'blink.cmp')
  if ok_blink and type(blink.get_lsp_capabilities) == 'function' then
    capabilities = blink.get_lsp_capabilities(capabilities)
  end

  local function setup_server_config(name, cfg)
    if cfg == true then
      cfg = {}
    elseif cfg == false or cfg == nil then
      return
    end

    cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
    vim.lsp.config(name, cfg)
  end

  local function auto_enable_server(name, cfg)
    if default_servers[name] ~= true then
      return
    end
    if cfg == false or cfg == nil then
      return
    end
    vim.lsp.enable(name)
  end

  for name, cfg in pairs(servers) do
    setup_server_config(name, cfg)
    auto_enable_server(name, cfg)
  end

  local ok_mason, mason_lsp = pcall(require, 'mason-lspconfig')
  if ok_mason then
    local mapping = require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package
    local ensure = {}
    local auto_enable_include = {}

    for name, cfg in pairs(default_servers) do
      if cfg == true then
        table.insert(auto_enable_include, name)
      end
    end

    for name, cfg in pairs(servers) do
      if default_servers[name] == true and cfg ~= false and mapping[name] then
        table.insert(ensure, name)
      end
    end
    mason_lsp.setup({
      ensure_installed = ensure,
      automatic_enable = auto_enable_include,
    })
  end

  vim.keymap.set('n', '<leader>cm', '<cmd>Mason<cr>', { desc = 'Mason' })
end

return M
