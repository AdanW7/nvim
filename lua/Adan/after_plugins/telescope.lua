-- =============================================================================
-- TELESCOPE SETUP
-- =============================================================================

local telescope = require('telescope')
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

-- Configure telescope before loading extensions
telescope.setup({
  defaults = {
    -- Layout
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        prompt_position = 'top',
        preview_width = 0.5,
        results_width = 0.8,
      },
      width = 0.95,
      height = 0.85,
      preview_cutoff = 120,
    },
    wrap_results = true,
    preview = {
      treesitter = {
        enable = true,
      },
    },

    -- Sorting
    sorting_strategy = 'ascending', -- First result at top

    -- Keymaps
    mappings = {
      i = { -- Insert mode
        ['<Tab>'] = actions.move_selection_next,
        ['<S-Tab>'] = actions.move_selection_previous,
        ['<C-j>'] = actions.move_selection_next,
        ['<C-k>'] = actions.move_selection_previous,
      },
      n = { -- Normal mode
        ['<Tab>'] = actions.move_selection_next,
        ['<S-Tab>'] = actions.move_selection_previous,
        ['j'] = actions.move_selection_next,
        ['k'] = actions.move_selection_previous,
      },
    },
  },
})

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

telescope.load_extension('projects')

-- =============================================================================
-- KEYMAPS - FILE FINDING
-- =============================================================================

-- Find files (global)
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })

-- Find files (current file's directory)
vim.keymap.set('n', '<leader>fF', function()
  builtin.find_files({ cwd = vim.fn.expand('%:p:h') })
end, { desc = 'Find files in current dir' })

-- Recent files
vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Telescope recent files' })

-- =============================================================================
-- KEYMAPS - SEARCH & GREP
-- =============================================================================

-- Grep (global)
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })

-- Grep (current file's directory)
vim.keymap.set('n', '<leader>fG', function()
  builtin.live_grep({ cwd = vim.fn.expand('%:p:h') })
end, { desc = 'Grep in current dir' })

-- =============================================================================
-- KEYMAPS - NAVIGATION
-- =============================================================================

-- Buffers
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })

-- Jumplist
vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Telescope jump list' })

-- Help tags
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

-- =============================================================================
-- KEYMAPS - PROJECTS
-- =============================================================================

-- Find projects (history)
vim.keymap.set(
  'n',
  '<leader>fp',
  '<cmd>NeovimProjectHistory<CR>',
  { desc = 'Find projects (history)' }
)

-- Discover projects (from patterns)
vim.keymap.set('n', '<leader>fP', '<cmd>NeovimProjectDiscover<CR>', { desc = 'Discover projects' })

-- Load recent project
vim.keymap.set(
  'n',
  '<leader>Pl',
  '<cmd>NeovimProjectLoadRecent<CR>',
  { desc = 'Load recent project' }
)

-- Project operations (after switching project)
vim.keymap.set('n', '<leader>Pf', function()
  builtin.find_files({ cwd = vim.fn.getcwd() })
end, { desc = 'Find files in project' })

vim.keymap.set('n', '<leader>Pg', function()
  builtin.live_grep({ cwd = vim.fn.getcwd() })
end, { desc = 'Grep in project' })

vim.keymap.set('n', '<leader>Pr', function()
  builtin.oldfiles({ cwd = vim.fn.getcwd() })
end, { desc = 'Recent files in project' })

-- =============================================================================
-- KEYMAPS - Diagnostics
-- =============================================================================

vim.keymap.set('n', '<leader>fd', function()
  require('telescope.builtin').diagnostics({
    bufnr = 0, -- Current buffer only
    severity_limit = nil, -- Show all severities (error, warn, info, hint)
    -- Or filter by severity:
    -- severity = vim.diagnostic.severity.ERROR, -- Only errors
  })
end, { desc = 'Find Diagnostics (buffer)' })

vim.keymap.set('n', '<leader>fD', function()
  require('telescope.builtin').diagnostics()
end, { desc = 'Find Diagnostics (workspace)' })

-- =============================================================================
-- KEYMAPS - LSP
-- =============================================================================

-- LSP symbols in current buffer
vim.keymap.set('n', '<leader>fs', builtin.lsp_document_symbols, { desc = 'Document symbols' })

-- LSP symbols in workspace
vim.keymap.set('n', '<leader>fS', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols' })

-- LSP references
vim.keymap.set('n', '<leader>fR', builtin.lsp_references, { desc = 'LSP references' })

-- LSP implementations
vim.keymap.set('n', '<leader>fi', builtin.lsp_implementations, { desc = 'LSP implementations' })

-- LSP definitions
vim.keymap.set('n', '<leader>fD', builtin.lsp_definitions, { desc = 'LSP definitions' })

-- =============================================================================
-- KEYMAPS - GIT
-- =============================================================================

-- Git status (modified files)
vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Git status' })

vim.keymap.set('n', '<leader>gf', function()
  builtin.git_files({
    git_command = { 'git', 'diff', '--name-only', 'HEAD', '--diff-filter=M' },
  })
end, { desc = 'Telescope git modified files' })

-- Git commits (current buffer)
vim.keymap.set('n', '<leader>gbc', builtin.git_bcommits, { desc = 'Git buffer commits' })

-- Git commits (all)
vim.keymap.set('n', '<leader>gC', builtin.git_commits, { desc = 'Git commits' })

-- Git stash
vim.keymap.set('n', '<leader>gS', builtin.git_stash, { desc = 'Git stash' })

-- =============================================================================
-- KEYMAPS - CURRENT BUFFER
-- =============================================================================

-- Search in current buffer
vim.keymap.set(
  'n',
  '<leader>/',
  builtin.current_buffer_fuzzy_find,
  { desc = 'Fuzzy find in buffer' }
)

-- =============================================================================
-- KEYMAPS - SEARCH
-- =============================================================================

-- Search history
vim.keymap.set('n', '<leader>f/', builtin.search_history, { desc = 'Search history' })

-- Command history
vim.keymap.set('n', '<leader>f:', builtin.command_history, { desc = 'Command history' })

-- Grep string under cursor
vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = 'Grep word under cursor' })

-- Marks
vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Marks' })

-- Registers
vim.keymap.set('n', '<leader>f"', builtin.registers, { desc = 'Registers' })

-- Keymaps
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Keymaps' })

-- =============================================================================
-- KEYMAPS - VIM
-- =============================================================================

-- Autocommands
vim.keymap.set('n', '<leader>fa', builtin.autocommands, { desc = 'Autocommands' })

-- Options
vim.keymap.set('n', '<leader>fo', builtin.vim_options, { desc = 'Vim options' })

-- Quickfix list
vim.keymap.set('n', '<leader>fq', builtin.quickfix, { desc = 'Quickfix list' })

-- Location list
vim.keymap.set('n', '<leader>fl', builtin.loclist, { desc = 'Location list' })
