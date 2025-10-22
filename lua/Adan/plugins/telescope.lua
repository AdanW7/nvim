local M = {}

function M.setup()
  vim.pack.add({
    'https://github.com/nvim-telescope/telescope.nvim',
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  }, { load = true, confirm = false })

  local telescope = require('telescope')
  local builtin = require('telescope.builtin')
  local actions = require('telescope.actions')
  local themes = require('telescope.themes')

  local function ensure_fzf_native()
    local path = vim.fn.stdpath('data') .. '/site/pack/core/opt/telescope-fzf-native.nvim'

    local ext = vim.fn.has('win32') == 1 and 'dll' or 'so'

    local lib = path .. '/build/libfzf.' .. ext

    if vim.fn.filereadable(lib) == 1 then
      return
    end

    vim.notify('Building telescope-fzf-native...')

    vim.system({ 'make' }, {
      cwd = path,
      text = true,
    }, function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          vim.notify('fzf-native built')
        else
          vim.notify(obj.stderr or 'build failed', vim.log.levels.ERROR)
        end
      end)
    end)
  end

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

  -- Fzf native load/warning
  local ok, err = pcall(telescope.load_extension, 'fzf')
  if not ok then
    vim.schedule(function()
      vim.notify(
        table.concat({
          'Failed to load telescope-fzf-native.',
          '',
          err,
        }, '\n'),
        vim.log.levels.WARN,
        { title = 'Telescope FZF Native' }
      )
    end)
  end

  -- keymaps

  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { desc = desc })
  end

  -- Resume last picker
  map('<leader>fe', builtin.resume, 'Resume last picker')

  -- Files
  map('<leader>ff', builtin.find_files, 'Find files')
  map('<leader>fF', function()
    builtin.find_files({ cwd = vim.fn.expand('%:p:h') })
  end, 'Find files in current dir')
  map('<leader>fr', builtin.oldfiles, 'Recent files')

  -- Grep
  map('<leader>fg', builtin.live_grep, 'Live grep')
  map('<leader>fG', function()
    builtin.live_grep({ cwd = vim.fn.expand('%:p:h') })
  end, 'Grep in current dir')
  map('<leader>fw', builtin.grep_string, 'Grep word under cursor')

  vim.keymap.set('v', '<leader>fw', function()
    local text = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'))
    builtin.grep_string({ search = table.concat(text, '\n') })
  end, { desc = 'Grep visual selection' })

  -- Navigation
  map('<leader>fb', builtin.buffers, 'Buffers')
  map('<leader>fj', builtin.jumplist, 'Jump list')
  map('<leader>fh', builtin.help_tags, 'Help tags')

  -- Diagnostics
  map('<leader>fd', function()
    builtin.diagnostics({ bufnr = 0 })
  end, 'Diagnostics (buffer)')

  -- LSP
  map('<leader>fs', builtin.lsp_document_symbols, 'Document symbols')
  map('<leader>fS', builtin.lsp_workspace_symbols, 'Workspace symbols')
  map('<leader>fR', builtin.lsp_references, 'LSP references')
  map('<leader>fi', builtin.lsp_implementations, 'LSP implementations')
  map('<leader>fD', builtin.lsp_definitions, 'LSP definitions')
  map('<leader>ft', builtin.lsp_type_definitions, 'LSP type definitions')

  -- Git
  map('<leader>gs', builtin.git_status, 'Git status')
  map('<leader>gf', function()
    builtin.git_files({ git_command = { 'git', 'diff', '--name-only', 'HEAD', '--diff-filter=M' } })
  end, 'Git modified files')
  map('<leader>gbc', builtin.git_bcommits, 'Git buffer commits')
  map('<leader>gB', builtin.git_branches, 'Git branches')
  map('<leader>gC', builtin.git_commits, 'Git commits')
  map('<leader>gS', builtin.git_stash, 'Git stash')

  -- Buffer / search
  map('<leader>/', builtin.current_buffer_fuzzy_find, 'Fuzzy find in buffer')
  map('<leader>f/', builtin.search_history, 'Search history')
  map('<leader>f:', builtin.command_history, 'Command history')
  map('<leader>fm', builtin.marks, 'Marks')
  map('<leader>f"', builtin.registers, 'Registers')
  map('<leader>fk', builtin.keymaps, 'Keymaps')

  -- Vim
  map('<leader>fa', builtin.autocommands, 'Autocommands')
  map('<leader>fo', builtin.vim_options, 'Vim options')
  map('<leader>fq', builtin.quickfix, 'Quickfix list')
  map('<leader>fQ', builtin.quickfixhistory, 'Quickfix history')
  map('<leader>fl', builtin.loclist, 'Location list')
  map('<leader>fM', builtin.man_pages, 'Man pages')
  map('<leader>fz', builtin.spell_suggest, 'Spell suggestions')

  -- Diff two files
  map('<leader>dv', function()
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
