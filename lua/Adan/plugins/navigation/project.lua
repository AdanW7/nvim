local M = {}

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
    local ok_project, project = pcall(require, 'project')
    if ok_project and type(project.get_config) == 'function' then
      vim.print(project.get_config())
      return
    end
    vim.notify('project config not available', vim.log.levels.WARN)
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

function M.setup()
  vim.pack.add({
    'https://github.com/DrKJeff16/project.nvim',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-telescope/telescope.nvim',
  }, { load = true, confirm = false })

  vim.opt.sessionoptions:append('globals')
  set_project_scope_telescope_keymaps()

  require('project').setup({
    manual_mode = true,
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
  })
  ensure_project_nvim_compat_commands()

  pcall(function()
    require('telescope').load_extension('projects')
  end)

  vim.keymap.set('n', '<leader>fp', function()
    open_telescope_projects()
  end, { desc = 'Find projects' })
  vim.keymap.set('n', '<leader>fP', '<cmd>ProjectRecents<CR>', { desc = 'Recent projects' })
  vim.keymap.set('n', '<leader>Pl', '<cmd>ProjectSession<CR>', { desc = 'Project session' })
  vim.keymap.set('n', '<leader>Pa', '<cmd>ProjectAdd<CR>', { desc = 'Project add' })
  vim.keymap.set('n', '<leader>PR', '<cmd>ProjectRoot<CR>', { desc = 'Project root' })
  vim.keymap.set('n', '<leader>PC', '<cmd>ProjectConfig<CR>', { desc = 'Project config' })
  vim.keymap.set('n', '<leader>PD', '<cmd>ProjectDelete<CR>', { desc = 'Project delete' })
  vim.keymap.set('n', '<leader>PS', '<cmd>ProjectSession<CR>', { desc = 'Project session picker' })
end

return M
