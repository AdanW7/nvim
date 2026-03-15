---@type LazySpec[]
return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason.nvim',
      { 'mason-org/mason-lspconfig.nvim', config = function() end },
    },
    opts = function()
      return {
        servers = {
          bashls = true,
          clangd = true,
          gleam = true,
          gopls = true,
          lua_ls = true,
          marksman = true,
          nixd = true,
          ocamllsp = false,
          rust_analyzer = true,
          texlab = true,
          ty = true,
          tombi = true,
          ruff = true,
          pyrefly = true,
          ts_ls = true,
          yamlls = true,
          zls = true,
          powershell_es = true,
          markdown_oxide = true,
        },
      }
    end,
    config = function(_, opts)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok_blink, blink = pcall(require, 'blink.cmp')
      if ok_blink and type(blink.get_lsp_capabilities) == 'function' then
        capabilities = blink.get_lsp_capabilities(capabilities)
      end

      local function setup_server(name, cfg)
        if cfg == true then
          cfg = {}
        elseif cfg == false or cfg == nil then
          return
        end

        cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
        vim.lsp.config(name, cfg)

        vim.lsp.enable(name)
      end

      for name, cfg in pairs(opts.servers) do
        setup_server(name, cfg)
      end

      local ok_mason, mason_lsp = pcall(require, 'mason-lspconfig')
      if ok_mason then
        local mapping = require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package
        local ensure = {}
        for name, cfg in pairs(opts.servers) do
          if cfg ~= false and mapping[name] then
            table.insert(ensure, name)
          end
        end
        mason_lsp.setup({ ensure_installed = ensure })
      end
    end,
  },
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    build = ':MasonUpdate',
    opts = {
      ensure_installed = {
        'stylua',
        'shfmt',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require('mason-registry')
      mr:on('package:install:success', function()
        vim.defer_fn(function()
          require('lazy.core.handler.event').trigger({
            event = 'FileType',
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
}
