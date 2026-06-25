local M = {}

local function ensure_fzf_native()
  local path = vim.fn.stdpath('data') .. '/site/pack/core/opt/telescope-fzf-native.nvim'
  local ext = vim.fn.has('win32') == 1 and 'dll' or 'so'
  local lib = path .. '/build/libfzf.' .. ext
  if vim.fn.filereadable(lib) == 1 then
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

function M.setup()
  load_telescope()

  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc })
  end

  local function b(picker, opts)
    return function()
      require('telescope.builtin')[picker](opts)
    end
  end

  local function bf(picker, get_opts)
    return function()
      require('telescope.builtin')[picker](get_opts())
    end
  end

  -- Resume
  map('<leader>fe', b('resume'), 'Resume last picker')

  -- Files
  map('<leader>ff', b('find_files'), 'Find files')
  map(
    '<leader>fF',
    bf('find_files', function()
      return { cwd = vim.fn.expand('%:p:h') }
    end),
    'Find files in current dir'
  )
  map('<leader>fr', b('oldfiles'), 'Recent files')

  -- Grep
  map('<leader>fg', b('live_grep'), 'Live grep')
  map(
    '<leader>fG',
    bf('live_grep', function()
      return { cwd = vim.fn.expand('%:p:h') }
    end),
    'Grep in current dir'
  )
  map('<leader>fw', b('grep_string'), 'Grep word under cursor')

  vim.keymap.set('v', '<leader>fw', function()
    local text = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'))
    require('telescope.builtin').grep_string({ search = table.concat(text, '\n') })
  end, { desc = 'Grep visual selection' })

  -- Navigation
  map('<leader>fb', b('buffers'), 'Buffers')
  map('<leader>fj', b('jumplist'), 'Jump list')
  map('<leader>fh', b('help_tags'), 'Help tags')

  -- Diagnostics
  map(
    '<leader>fd',
    bf('diagnostics', function()
      return { bufnr = 0 }
    end),
    'Diagnostics (buffer)'
  )

  -- LSP
  map('<leader>fs', b('lsp_document_symbols'), 'Document symbols')
  map('<leader>fS', b('lsp_workspace_symbols'), 'Workspace symbols')
  map('<leader>fR', b('lsp_references'), 'LSP references')
  map('<leader>fi', b('lsp_implementations'), 'LSP implementations')
  map('<leader>fD', b('lsp_definitions'), 'LSP definitions')
  map('<leader>ft', b('lsp_type_definitions'), 'LSP type definitions')

  -- Git
  map('<leader>gs', b('git_status'), 'Git status')
  map(
    '<leader>gf',
    bf('git_files', function()
      return { git_command = { 'git', 'diff', '--name-only', 'HEAD', '--diff-filter=M' } }
    end),
    'Git modified files'
  )
  map('<leader>gbc', b('git_bcommits'), 'Git buffer commits')
  map('<leader>gB', b('git_branches'), 'Git branches')
  map('<leader>gC', b('git_commits'), 'Git commits')
  map('<leader>gS', b('git_stash'), 'Git stash')

  -- Buffer / search
  map('<leader>/', b('current_buffer_fuzzy_find'), 'Fuzzy find in buffer')
  map('<leader>f/', b('search_history'), 'Search history')
  map('<leader>f:', b('command_history'), 'Command history')
  map('<leader>fm', b('marks'), 'Marks')
  map('<leader>f"', b('registers'), 'Registers')
  map('<leader>fk', b('keymaps'), 'Keymaps')

  -- Vim
  map('<leader>fa', b('autocommands'), 'Autocommands')
  map('<leader>fo', b('vim_options'), 'Vim options')
  map('<leader>fq', b('quickfix'), 'Quickfix list')
  map('<leader>fQ', b('quickfixhistory'), 'Quickfix history')
  map('<leader>fl', b('loclist'), 'Location list')
  map('<leader>fM', b('man_pages'), 'Man pages')
  map('<leader>fz', b('spell_suggest'), 'Spell suggestions')

  -- Diff two files
  map('<leader>dv', function()
    local builtin = require('telescope.builtin')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    builtin.find_files({
      prompt_title = 'Diff: Select first file',
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local first = action_state.get_selected_entry().path
          actions.close(prompt_bufnr)
          builtin.find_files({
            prompt_title = 'Diff: Select second file (first: '
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
  end, 'Diff two files via picker')
end

return M
