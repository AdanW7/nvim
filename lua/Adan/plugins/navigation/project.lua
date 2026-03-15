local use_project_nvim = true

local function open_telescope_projects()
  local ok_telescope, telescope = pcall(require, 'telescope')
  if ok_telescope then
    pcall(telescope.load_extension, 'projects')
    local projects_ext = telescope.extensions and telescope.extensions.projects or nil
    if projects_ext and type(projects_ext.projects) == 'function' then
      projects_ext.projects()
      return
    end
    pcall(vim.cmd, 'Telescope projects')
    return
  end
  pcall(vim.cmd, 'ProjectTelescope')
end

local function ensure_project_nvim_compat_commands()
  local function define(name, rhs)
    pcall(vim.api.nvim_create_user_command, name, rhs, {})
  end

  define('ProjectTelescope', function()
    open_telescope_projects()
  end)

  define('ProjectRecents', function()
    open_telescope_projects()
  end)

  define('ProjectSession', function()
    open_telescope_projects()
  end)

  define('ProjectAdd', function()
    if vim.fn.exists(':AddProject') == 2 then
      vim.cmd('AddProject')
    else
      vim.cmd('ProjectRoot')
    end
  end)

  define('ProjectConfig', function()
    local ok_cfg, cfg = pcall(require, 'project_nvim.config')
    if ok_cfg then
      vim.print(cfg.options)
      return
    end
    vim.notify('project_nvim config not available', vim.log.levels.WARN)
  end)

  define('ProjectDelete', function()
    open_telescope_projects()
    vim.notify('Use "d" in the projects picker to delete an entry', vim.log.levels.INFO)
  end)
end

local function set_project_scope_telescope_keymaps()
  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>Pf', function()
    builtin.find_files({ cwd = vim.fn.getcwd() })
  end, { desc = 'Find files in project' })

  vim.keymap.set('n', '<leader>Pg', function()
    builtin.live_grep({ cwd = vim.fn.getcwd() })
  end, { desc = 'Grep in project' })

  vim.keymap.set('n', '<leader>Pr', function()
    builtin.oldfiles({ cwd = vim.fn.getcwd() })
  end, { desc = 'Recent files in project' })
end

---@type Adan.LazySpec
local neovim_project_spec = {
  'coffebar/neovim-project',
  opts = {
    projects = {
      '~/.config/*',
      '~/orgfiles',
      'C:/MTRepos/*',
      'C:/Users/awodzins/OneDrive - Milwaukee Tool/Documents/Notes',
    },
    last_session_on_startup = false,
    dashboard_mode = true,
    session_manager_opts = {
      autosave_ignore_dirs = {
        vim.fn.expand('~'),
        '/tmp',
      },
      autosave_ignore_filetypes = {
        'gitcommit',
        'gitrebase',
        'qf',
        'toggleterm',
      },
    },
    picker = {
      type = 'telescope',
    },
  },
  init = function()
    vim.opt.sessionoptions:append('globals')
    set_project_scope_telescope_keymaps()
  end,
  config = function()
    pcall(function()
      require('telescope').load_extension('projects')
    end)
  end,
  keys = {
    { '<leader>fp', '<cmd>NeovimProjectHistory<CR>', desc = 'Find projects (history)' },
    { '<leader>fP', '<cmd>NeovimProjectDiscover<CR>', desc = 'Discover projects' },
    { '<leader>Pl', '<cmd>NeovimProjectLoadRecent<CR>', desc = 'Load recent project' },
  },
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope.nvim' },
    { 'Shatur/neovim-session-manager' },
  },
  lazy = false,
  priority = 100,
}

---@type Adan.LazySpec
local project_nvim_spec = {
  'DrKJeff16/project.nvim',
  opts = {
    manual_mode = false,
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    update_focused_file = {
      enable = true,
      update_root = true,
    },
    patterns = {
      '.git',
      'pyproject.toml',
      'package.json',
      'go.mod',
      'Cargo.toml',
      'dune-project',
      'flake.nix',
      'Makefile',
    },
    lsp = {
      enabled = true,
      use_pattern_matching = true,
      no_fallback = false,
      ignore = {},
    },
    telescope = {
      enabled = true,
      sort = 'newest',
      prefer_file_browser = false,
      disable_file_picker = false,
    },
    snacks = {
      enabled = false,
    },
    picker = {
      enabled = false,
    },
    fzf_lua = {
      enabled = false,
    },
  },
  init = function()
    vim.opt.sessionoptions:append('globals')
    set_project_scope_telescope_keymaps()
  end,
  config = function(_, opts)
    require('project_nvim').setup(opts)
    ensure_project_nvim_compat_commands()
    pcall(function()
      require('telescope').load_extension('projects')
    end)
  end,
  keys = {
    {
      '<leader>fp',
      function()
        open_telescope_projects()
      end,
      desc = 'Find projects',
    },
    {
      '<leader>fP',
      function()
        vim.cmd('ProjectRecents')
      end,
      desc = 'Recent projects',
    },
    {
      '<leader>Pl',
      function()
        vim.cmd('ProjectSession')
      end,
      desc = 'Project session',
    },
    {
      '<leader>Pa',
      function()
        vim.cmd('ProjectAdd')
      end,
      desc = 'Project add',
    },
    {
      '<leader>PR',
      function()
        vim.cmd('ProjectRoot')
      end,
      desc = 'Project root',
    },
    {
      '<leader>PC',
      function()
        vim.cmd('ProjectConfig')
      end,
      desc = 'Project config',
    },
    {
      '<leader>PD',
      function()
        vim.cmd('ProjectDelete')
      end,
      desc = 'Project delete',
    },
    {
      '<leader>PS',
      function()
        vim.cmd('ProjectSession')
      end,
      desc = 'Project session picker',
    },
  },
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope.nvim' },
  },
  lazy = false,
  priority = 100,
}

---@type Adan.LazySpec
local selected_spec = use_project_nvim and project_nvim_spec or neovim_project_spec

return selected_spec
