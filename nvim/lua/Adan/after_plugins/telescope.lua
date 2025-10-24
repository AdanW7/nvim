-- =============================================================================
-- TELESCOPE SETUP
-- =============================================================================

local telescope = require("telescope")
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
        preview_width = 0.55,
        results_width = 0.8,
      },
      width = 0.95,
      height = 0.85,
      preview_cutoff = 120,
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

telescope.load_extension("projects")


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

-- Find projects
vim.keymap.set('n', '<leader>fp', '<cmd>Telescope projects<CR>', { desc = 'Find projects' })

-- Project operations (after switching project)
vim.keymap.set('n', '<leader>pf', function()
    builtin.find_files({ cwd = vim.fn.getcwd() })
end, { desc = 'Find files in project' })

vim.keymap.set('n', '<leader>pg', function()
    builtin.live_grep({ cwd = vim.fn.getcwd() })
end, { desc = 'Grep in project' })

vim.keymap.set('n', '<leader>pr', function()
    builtin.oldfiles({ cwd = vim.fn.getcwd() })
end, { desc = 'Recent files in project' })


-- =============================================================================
-- KEYMAPS - PROJECT MANAGEMENT
-- =============================================================================

-- Add current directory as project
vim.keymap.set('n', '<leader>pa', function()
    local history = require("project_nvim.utils.history")
    local cwd = vim.fn.getcwd()
    
    -- Check if already in history
    for _, v in pairs(history.recent_projects) do
        if v == cwd then
            vim.notify("Project already in history: " .. cwd, vim.log.levels.INFO)
            return
        end
    end
    
    -- Add to recent projects
    table.insert(history.recent_projects, 1, cwd)
    history.write_projects_to_history()
    vim.notify("Added '" .. cwd .. "' to projects", vim.log.levels.INFO)
end, { desc = 'Add current dir as project' })

-- Add custom directory as project
vim.keymap.set('n', '<leader>pA', function()
    vim.ui.input({ prompt = "Project path: ", completion = "dir" }, function(path)
        if path and path ~= "" then
            local expanded = vim.fn.expand(path)
            
            if vim.fn.isdirectory(expanded) == 1 then
                local history = require("project_nvim.utils.history")
                
                -- Check if already exists
                for _, v in pairs(history.recent_projects) do
                    if v == expanded then
                        vim.notify("Project already in history: " .. expanded, vim.log.levels.INFO)
                        return
                    end
                end
                
                -- Add and save
                table.insert(history.recent_projects, 1, expanded)
                history.write_projects_to_history()
                vim.notify("Added '" .. expanded .. "' to projects", vim.log.levels.INFO)
            else
                vim.notify("Invalid directory: " .. expanded, vim.log.levels.ERROR)
            end
        end
    end)
end, { desc = 'Add folder as project' })
