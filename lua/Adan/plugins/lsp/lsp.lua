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
      local function root_pattern(patterns)
        return function(fname)
          local path = fname and fname ~= '' and fname or vim.api.nvim_buf_get_name(0)
          if path == '' then
            return (vim.uv or vim.loop).cwd()
          end
          return vim.fs.root(path, patterns) or (vim.uv or vim.loop).cwd()
        end
      end

      return {
        servers = {
          bashls = true,
          clangd = true,
          gleam = true,
          gopls = true,
          lua_ls = true,
          marksman = true,
          nixd = true,
          ocamllsp = true,
          rust_analyzer = true,
          texlab = true,
          ty = true,
          ts_ls = true,
          yamlls = true,
          zls = true,

          powershell_es = {
            bundle_path = vim.env.POWERSHELL_ES_BUNDLE_PATH or 'C:/Tools',
            shell = 'powershell.exe',
            filetypes = { 'ps1' },
            root_dir = root_pattern({ 'PSScriptAnalyzerSettings.psd1', '.git' }),
          },
          ruff = {
            cmd = { 'ruff', 'server', '--preview' },
            filetypes = { 'python' },
            root_dir = root_pattern({
              'pyproject.toml',
              'pyrightconfig.json',
              'ruff.toml',
              '.ruff.toml',
              'setup.py',
              'setup.cfg',
              'requirements.txt',
              'Pipfile',
              '.git',
            }),
            settings = {
              exclude = {
                '.bzr',
                '.direnv',
                '.eggs',
                '.git',
                '.git-rewrite',
                '.hg',
                '.ipynb_checkpoints',
                '.mypy_cache',
                '.nox',
                '.pants.d',
                '.pyenv',
                '.pytest_cache',
                '.pytype',
                '.ruff_cache',
                '.svn',
                '.tox',
                '.venv',
                '.vscode',
                '__pypackages__',
                '_build',
                'buck-out',
                'build',
                'dist',
                'node_modules',
                'site-packages',
                'venv',
              },
              ['indent-width'] = 4,
              ['line-length'] = 120,
              ['target-version'] = 'py311',
              format = {
                ['indent-style'] = 'space',
                ['line-ending'] = 'auto',
                preview = true,
                ['quote-style'] = 'double',
                ['skip-magic-trailing-comma'] = false,
              },
              lint = {
                fixable = { 'ALL' },
                ignore = { 'E501', 'F403', 'F405' },
                preview = true,
                select = { 'E4', 'E7', 'E9', 'F', 'B' },
                unfixable = { 'B' },
              },
            },
          },
          pyrefly = {
            cmd = { 'pyrefly', 'lsp' },
            filetypes = { 'python' },
            root_dir = root_pattern({
              'pyrefly.toml',
              'pyproject.toml',
              'setup.py',
              'setup.cfg',
              'requirements.txt',
              'Pipfile',
              '.git',
            }),
            init_options = {
              pyrefly = {
                displayTypeErrors = 'force-on',
                skipLspConfigIndexing = true,
              },
            },
          },
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
