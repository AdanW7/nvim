local M = {}

local function ensure_fzf_native()
  local path = vim.fn.stdpath('data') .. '/site/pack/core/opt/telescope-fzf-native.nvim'
  local ext = vim.fn.has('win32') == 1 and 'dll' or 'so'
  local lib = path .. '/build/libfzf.' .. ext
  if vim.fn.filereadable(lib) == 1 then
    return
  end
  if vim.fn.executable('make') == 0 then
    vim.notify(
      'telescope-fzf-native is not built and `make` is not available on PATH.',
      vim.log.levels.WARN,
      { title = 'Telescope FZF Native' }
    )
    return
  end
  vim.notify('Building telescope-fzf-native...')
  vim.system({ 'make' }, { cwd = path, text = true }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify('fzf-native built')
      else
        vim.notify(obj.stderr or 'build failed', vim.log.levels.ERROR)
      end
    end)
  end)
end

local function load_telescope()
  if package.loaded['telescope'] then
    return
  end

  vim.pack.add({
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  }, { load = true, confirm = false })

  local telescope = require('telescope')
  local actions = require('telescope.actions')
  local themes = require('telescope.themes')

  telescope.setup({
    defaults = themes.get_ivy({
      layout_config = {
        height = 0.5,
        preview_cutoff = 120,
      },
      wrap_results = true,
      preview = { treesitter = { enable = true } },
      sorting_strategy = 'ascending',
      mappings = {
        i = {
          ['<Tab>'] = actions.move_selection_next,
          ['<S-Tab>'] = actions.move_selection_previous,
          ['<C-j>'] = actions.move_selection_next,
          ['<C-k>'] = actions.move_selection_previous,
        },
        n = {
          ['<Tab>'] = actions.move_selection_next,
          ['<S-Tab>'] = actions.move_selection_previous,
          ['j'] = actions.move_selection_next,
          ['k'] = actions.move_selection_previous,
        },
      },
    }),
    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = 'smart_case',
      },
    },
  })

  ensure_fzf_native()

  local ok, err = pcall(telescope.load_extension, 'fzf')
  if not ok then
    vim.notify(
      table.concat({ 'Failed to load telescope-fzf-native.', '', err }, '\n'),
      vim.log.levels.WARN,
      { title = 'Telescope FZF Native' }
    )
  end

  vim.api.nvim_exec_autocmds('User', { pattern = 'TelescopeReady' })
end

M.load = load_telescope

-- ---------------------------------------------------------------------------
-- Picker helpers
-- ---------------------------------------------------------------------------

---Picker with fixed options.
---@param picker string
---@param opts? table
local function b(picker, opts)
  return function()
    require('telescope.builtin')[picker](opts)
  end
end

---Picker with options resolved lazily at call time.
---@param picker string
---@param get_opts fun(): table
local function bf(picker, get_opts)
  return function()
    require('telescope.builtin')[picker](get_opts())
  end
end

---Workspace-scoped picker: merges cwd = workspace.root() at call time.
---@param picker string
---@param opts? table
local function wb(picker, opts)
  return function()
    require('telescope.builtin')[picker](
      vim.tbl_extend('force', { cwd = require('Adan.core.workspace').root() }, opts or {})
    )
  end
end

---Workspace-scoped picker with lazily resolved extra options.
---@param picker string
---@param get_opts fun(): table
local function wbf(picker, get_opts)
  return function()
    require('telescope.builtin')[picker](
      vim.tbl_extend('force', { cwd = require('Adan.core.workspace').root() }, get_opts())
    )
  end
end

-- ---------------------------------------------------------------------------
-- Keymap setup
-- ---------------------------------------------------------------------------

function M.setup()
  load_telescope()

  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc })
  end

  -- Resume
  map('<leader>fe', b('resume'), 'Telescope: resume last picker')

  -- Files (workspace-scoped)
  map('<leader>ff', wb('find_files'), 'Telescope: find files')
  map('<leader>fr', wb('oldfiles'), 'Telescope: recent files')
  map(
    '<leader>fF',
    wbf('find_files', function()
      return { cwd = vim.fn.expand('%:p:h') }
    end),
    'Telescope: find files in buffer dir'
  )

  -- Grep (workspace-scoped)
  map('<leader>fg', wb('live_grep'), 'Telescope: live grep')
  map('<leader>fw', wb('grep_string'), 'Telescope: grep word under cursor')
  map(
    '<leader>fG',
    wbf('live_grep', function()
      return { cwd = vim.fn.expand('%:p:h') }
    end),
    'Telescope: grep in buffer dir'
  )

  vim.keymap.set('v', '<leader>fw', function()
    local text = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'))
    require('telescope.builtin').grep_string({
      search = table.concat(text, '\n'),
      cwd = require('Adan.core.workspace').root(),
    })
  end, { desc = 'Telescope: grep visual selection' })

  -- Navigation (not workspace-scoped — global by nature)
  map('<leader>fb', b('buffers'), 'Telescope: buffers')
  map('<leader>fj', b('jumplist'), 'Telescope: jump list')
  map('<leader>fh', b('help_tags'), 'Telescope: help tags')

  -- Diagnostics
  map(
    '<leader>fd',
    bf('diagnostics', function()
      return { bufnr = 0 }
    end),
    'Telescope: buffer diagnostics'
  )

  -- LSP
  map('<leader>fs', b('lsp_document_symbols'), 'Telescope: document symbols')
  map('<leader>fS', wb('lsp_workspace_symbols'), 'Telescope: workspace symbols')
  map('<leader>fR', b('lsp_references'), 'Telescope: LSP references')
  map('<leader>fi', b('lsp_implementations'), 'Telescope: LSP implementations')
  map('<leader>fD', b('lsp_definitions'), 'Telescope: LSP definitions')
  map('<leader>ft', b('lsp_type_definitions'), 'Telescope: LSP type definitions')

  -- Git (workspace-scoped)
  map('<leader>gs', wb('git_status'), 'Telescope: git status')
  map('<leader>gbc', b('git_bcommits'), 'Telescope: git buffer commits')
  map('<leader>gB', b('git_branches'), 'Telescope: git branches')
  map('<leader>gC', b('git_commits'), 'Telescope: git commits')
  map('<leader>gS', b('git_stash'), 'Telescope: git stash')
  map(
    '<leader>gf',
    wb('git_files', { git_command = { 'git', 'diff', '--name-only', 'HEAD', '--diff-filter=M' } }),
    'Telescope: git modified files'
  )

  -- Buffer / search
  map('<leader>/', b('current_buffer_fuzzy_find'), 'Telescope: fuzzy find in buffer')
  map('<leader>f/', b('search_history'), 'Telescope: search history')
  map('<leader>f:', b('command_history'), 'Telescope: command history')
  map('<leader>fm', b('marks'), 'Telescope: marks')
  map('<leader>f"', b('registers'), 'Telescope: registers')
  map('<leader>fk', b('keymaps'), 'Telescope: keymaps')

  -- Vim
  map('<leader>fa', b('autocommands'), 'Telescope: autocommands')
  map('<leader>fo', b('vim_options'), 'Telescope: vim options')
  map('<leader>fq', b('quickfix'), 'Telescope: quickfix list')
  map('<leader>fQ', b('quickfixhistory'), 'Telescope: quickfix history')
  map('<leader>fl', b('loclist'), 'Telescope: location list')
  map('<leader>fM', b('man_pages'), 'Telescope: man pages')
  map('<leader>fz', b('spell_suggest'), 'Telescope: spell suggestions')

  -- Workspace root picker (telescope-powered, so it lives here not in keymaps.lua)
  map('<leader>tW', function()
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local finders = require('telescope.finders')
    local pickers = require('telescope.pickers')
    local conf = require('telescope.config').values

    local function open_picker(cwd)
      pickers
        .new({}, {
          prompt_title = 'Set workspace root (' .. vim.fn.fnamemodify(cwd, ':~') .. ')',
          finder = finders.new_oneshot_job({
            'fd',
            '--type',
            'd',
            '--max-depth',
            '4',
            '--hidden',
            '--exclude',
            '.git',
            '--base-directory',
            cwd,
          }, {
            entry_maker = function(line)
              local abs = vim.fn.fnamemodify(cwd .. '/' .. line, ':p'):gsub('[/\\]$', '')
              return { value = abs, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(bufnr, map_inner)
            actions.select_default:replace(function()
              local sel = action_state.get_selected_entry()
              actions.close(bufnr)
              require('Adan.core.workspace').set_root(sel.value)
            end)

            map_inner('i', '<C-u>', function()
              local parent = vim.fn.fnamemodify(cwd, ':h')
              if parent == cwd then
                return
              end -- already at fs root
              actions.close(bufnr)
              vim.schedule(function()
                open_picker(parent)
              end)
            end)

            return true
          end,
        })
        :find()
    end

    open_picker(vim.fn.getcwd())
  end, 'Telescope: pick workspace root')

  -- Diff two files
  map('<leader>dv', function()
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    builtin.find_files({
      prompt_title = 'Diff: select first file',
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local first = action_state.get_selected_entry().path
          actions.close(prompt_bufnr)
          builtin.find_files({
            prompt_title = 'Diff: select second file (first: '
              .. vim.fn.fnamemodify(first, ':~:.')
              .. ')',
            attach_mappings = function(prompt_bufnr2)
              actions.select_default:replace(function()
                local second = action_state.get_selected_entry().path
                actions.close(prompt_bufnr2)
                require('difftool').open(first, second)
              end)
              return true
            end,
          })
        end)
        return true
      end,
    })
  end, 'Telescope: diff two files')
end

return M
